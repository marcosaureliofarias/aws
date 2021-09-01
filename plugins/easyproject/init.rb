require 'pp'
require_relative './lib/easyproject/patch_manager'
require_relative './lib/easyproject/easy_optimized_file_resolver'

Rails.application.config.enable_dependency_loading = true # todo, use eager load

if RUBY_VERSION < '2.3'
  $stderr.puts 'Only Ruby 2.3.0 and higher is supported!'
  exit 1
end

module Redmine
  class Plugin

    @bundled_plugin_ids = {}
    @disabled_plugins   = {}
    class << self
      attr_reader :disabled_plugins
      attr_accessor :bundled_plugin_ids

      def all_hosting_plugins
        @all_hosting_plugins ||= ::EasyHostingPlugin.all.each_with_object({}) { |plugin, o| o[plugin.plugin_name] = plugin }
      end
    end

    def_field :visible, :migration_order, :version_description, :disabled,
              :should_be_disabled, :store_url, :depends_on, :categories,
              :schedule_file
    attr_reader :complete_directory_path

    def plugin_in_relative_subdirectory(subdir)
      @complete_directory_path = File.join(self.class.directory, subdir)
    end

    def visible?
      @visible = true if @visible.nil?
      visible == true
    end

    def disabled?
      return false if !Redmine::Plugin.installed?(:easy_hosting_services)
      return false if Rails.env.test? || !EasyHostingPlugin.table_exists?
      return false if !should_be_disabled? # || !self.is_easy_plugin?

      plugin = self.class.all_hosting_plugins[self.id.to_s] ||= ::EasyHostingPlugin.create(plugin_name: self.id.to_s)
      plugin.plugin_disabled?
    end

    def should_be_disabled?
      @should_be_disabled = true if @should_be_disabled.nil?
      should_be_disabled == true
    end

    def is_easy_plugin?
      directory.start_with?(File.join(Rails.root, EasyExtensions::RELATIVE_EASYPROJECT_PLUGIN_PATH))
    end

    def schedule_yaml
      file = File.join(self.directory, @schedule_file) if @schedule_file
      file ||= File.join(self.directory, 'config/schedule.yml')

      YAML.load_file(file) if File.exists?(file)
    end

    def self.all(options = nil)
      options          ||= {}
      only_visible     = options.key?(:only_visible) ? options.delete(:only_visible) : false
      without_disabled = options.key?(:without_disabled) ? options.delete(:without_disabled) : false

      arr = []
      arr.concat registered_plugins.values
      arr.concat disabled_plugins.values unless without_disabled

      easy_helpers_plugins = []; core_plugins = []; easy_plugins = []; redmine_plugins = []; modifications_plugins = []

      arr.sort.each do |plugin|
        next if only_visible && !plugin.visible?
        case plugin.id.to_s
        when *EasyProjectLoader::CORE_PLUGINS
          core_plugins << plugin
        when EasyProjectLoader::MOD_PLUGINS_REGEXP
          modifications_plugins << plugin
        else
          case File.dirname(plugin.directory)
          when File.join(directory, 'easyproject', 'easy_helpers')
            easy_helpers_plugins << plugin
          when directory
            redmine_plugins << plugin
          else
            easy_plugins << plugin
          end
        end
      end

      easy_helpers_plugins + core_plugins + easy_plugins + redmine_plugins + modifications_plugins
    end

    def requires_redmine_plugin(plugin_name, arg)
      arg = { :version_or_higher => arg } unless arg.is_a?(Hash)
      arg.assert_valid_keys(:version, :version_or_higher)

      plugin = Plugin.find_or_nil(plugin_name)
      raise PluginRequirementError.new("#{id} plugin requires the #{plugin_name} plugin") if plugin.nil?
      current = plugin.version.split('.').collect(&:to_i)

      arg.each do |k, v|
        v        = [] << v unless v.is_a?(Array)
        versions = v.collect { |s| s.split('.').collect(&:to_i) }
        case k
        when :version_or_higher
          raise ArgumentError.new("wrong number of versions (#{versions.size} for 1)") unless versions.size == 1
          unless (current <=> versions.first) >= 0
            raise PluginRequirementError.new("#{id} plugin requires the #{plugin_name} plugin #{v} or higher but current is #{current.join('.')}")
          end
        when :version
          unless versions.include?(current.slice(0, 3))
            raise PluginRequirementError.new("#{id} plugin requires one the following versions of #{plugin_name}: #{v.join(', ')} but current is #{current.join('.')}")
          end
        end
      end
      true
    end

    def self.find_or_nil(id)
      p = registered_plugins[id.to_sym]
      p ||= disabled_plugins[id.to_sym]
      p
    end

    def self.disabled?(id)
      return true if id.nil?
      Redmine::Plugin.disabled_plugins.key?(id.to_sym)
    end

    def self.installation?
      if Object.const_defined?(:Rake) && Rake.respond_to?(:application)
        tasks = Rake.application.top_level_tasks.join
        tasks.respond_to?(:match?) ? tasks.match?(EasyExtensions::INSTALLATION_TASKS) : tasks.match(EasyExtensions::INSTALLATION_TASKS)
      else
        false
      end
    end

    def self.register(id, &block)
      p = new(id)
      p.instance_eval(&block)

      p.name(id.to_s.humanize) if p.name.nil?
      p.directory(File.join(p.complete_directory_path || self.directory, id.to_s)) if p.directory.nil?

      plugin_path = Pathname.new(p.directory)

      Rails.application.config.i18n.load_path += Dir.glob(plugin_path.join('config', 'locales', '*.yml'))

      if (p.id != :easy_extensions) && p.disabled? && !installation?
        disabled_plugins[id] = p
        return
      end

      Dir.glob File.expand_path(plugin_path.join('app', '{controllers,helpers,jobs,models,models/api_services_for_exchange_rates,models/concerns,models/easy_entity_actions,models/easy_page_modules,models/easy_queries,models/easy_rakes,sweepers}')) do |dir|
        ActiveSupport::Dependencies.autoload_paths += [dir]
      end

      if (lib = plugin_path.join('lib')).exist?
        $:.unshift lib
        ActiveSupport::Dependencies.autoload_paths += [lib]
      end

      registered_plugins[id] = p

      if plugin_path.parent.basename.to_s != 'plugins' && (file = plugin_path.join('config', 'routes.rb')).exist?
        begin
          RedmineApp::Application.routes.prepend do
            instance_eval File.read(file)
          end
        rescue Exception => e
          puts "An error occurred while loading the routes definition of #{plugin_path.basename} plugin (#{file}): #{e.message}."
          exit 1
        end
      end

      if (view_path = plugin_path.join('app', 'views')).exist?
        ActionController::Base.prepend_view_path(ActionView::EasyOptimizedFileSystemResolver.new(view_path))
        ActionMailer::Base.prepend_view_path(view_path)
      end

      if p.settings
        Setting.define_plugin_setting p
      end

      if p.configurable?
        partial = p.settings[:partial]
        if @used_partials[partial]
          Rails.logger.warn "WARNING: settings partial '#{partial}' is declared in '#{p.id}' plugin but it is already used by plugin '#{@used_partials[partial]}'. Only one settings view will be used. You may want to contact those plugins authors to fix this."
        end
        @used_partials[partial] = p.id
      end

      Rails.application.configure do
        config.assets.precompile += Dir.glob(File.join(p.assets_directory, '{stylesheets,javascripts}', "#{id}.{css,js,scss}")) + Dir.glob(File.join(p.assets_directory, 'images', '**', '*'))

        if p.id == :easy_project_com || p.id == :easy_redmine
          config.assets.paths = Dir.glob(File.join(p.assets_directory, '{stylesheets,javascripts,images}')) + config.assets.paths
        else
          config.assets.paths.concat Dir.glob(File.join(p.assets_directory, '{stylesheets,javascripts,images}'))
        end
      end

      if (initializer = plugin_path.join('after_init.rb')).exist?
        require initializer
      end

      patches_dir = plugin_path.join('patches')

      if patches_dir.exist?
        patches_files = Dir.glob(File.join(patches_dir, '**/*.rb'))

        # load is because of hot-reload
        # `Kernel.load` is because in this context `.load` is `Redmine::Plugin.load`
        patches_files.each {|f| Kernel.load(f) }
      end

      if Rails.env.test? && (test_initializer = plugin_path.join('test_init.rb')).exist?
        require test_initializer
      end

      true
    end

    def self.migrate(name=nil, version=nil)
      if name.present?
        p = find_or_nil(name)
        p.migrate(version) if p
      else
        all.each do |plugin|
          plugin.migrate
        end
      end
    end

    def self.migrate_easy_data(name=nil, version=nil)
      if name.present?
        p = find_or_nil(name)
        p.migrate_easy_data(version) if p
      else
        all.each do |plugin|
          plugin.migrate_easy_data
        end
      end
    end

    def self.plugins_in_category(category, options={})
      Redmine::Plugin.all(options).select { |plugin| Array(bundled_plugin_ids[category.to_sym]).include?(plugin.id.to_sym) }
    end

    def migrate_easy_data(version = nil)
      puts "Migrating data for #{id} (#{name})..."
      EasyExtensions::DataMigrator.migrate_plugin(self, version)
    end

    def migration_easy_data_directory
      File.join(directory, 'db', 'data')
    end

    def dependent_plugins(options={})
      @dependent_plugins ||= Redmine::Plugin.all(options).select { |p| Array(p.depends_on).include?(self.id.to_sym) }
    end

    def depends_on_plugins
      @depends_on_plugins ||= Array(self.depends_on).collect { |d| self.class.find_or_nil(d) }.compact
    end

    def belongs_to_categories
      @belongs_to_categories ||= Array(Redmine::Plugin.bundled_plugin_ids.find { |_, p_ids| Array(p_ids).include?(id.to_sym) }.try(:first))
    end

    def self.available_easy_hosting_plugins
      @@available_easy_hosting_plugins ||= EasyHostingPlugin.order(:plugin_name).to_a
    end

    def easy_hosting_plugin
      @easy_hosting_plugin ||= self.class.available_easy_hosting_plugins.detect { |p| p.plugin_name == self.id.to_s }
    end


    # remove after http://www.redmine.org/issues/28934
    class MigrationContext < ActiveRecord::MigrationContext
      def up(target_version = nil)
        selected_migrations = if block_given?
          migrations.select { |m| yield m }
        else
          migrations
        end
        Migrator.new(:up, selected_migrations, target_version).migrate
      end

      def down(target_version = nil)
        selected_migrations = if block_given?
          migrations.select { |m| yield m }
        else
          migrations
        end
        Migrator.new(:down, selected_migrations, target_version).migrate
      end

      def run(direction, target_version)
        Migrator.new(direction, migrations, target_version).run
      end

      def open
        Migrator.new(:up, migrations, nil)
      end
    end

    class Migrator < ActiveRecord::Migrator

      def self.migrate_plugin(plugin, version)
        self.current_plugin = plugin
        return if current_version(plugin) == version
        MigrationContext.new(plugin.migration_directory).migrate(version)
      end

      def self.get_all_versions(plugin = current_plugin)
        @all_versions ||= {}
        @all_versions[plugin.id.to_s] ||= begin
          sm_table = ::ActiveRecord::SchemaMigration.table_name
          migration_versions  = ActiveRecord::Base.connection.select_values("SELECT version FROM #{sm_table}")
          versions_by_plugins = migration_versions.group_by { |version| version.match(/-(.*)$/).try(:[], 1) }
          @all_versions       = versions_by_plugins.transform_values! {|versions| versions.map!(&:to_i).sort! }
          @all_versions[plugin.id.to_s] || []
        end
      end

      def self.needs_migration?
        (MigrationContext.new(current_plugin.migration_directory).migrations.collect(&:version) - get_all_versions).any?
      end

      def self.current_version(plugin=current_plugin)
        get_all_versions(plugin).last || 0
      end

      def self.assume_migrated_upto_version(version)
        sm_table = ::ActiveRecord::SchemaMigration.table_name
        migrations_paths = Array(current_plugin.migration_directory)
        version          = version.to_i

        migrated = get_all_versions
        paths    = migrations_paths.map { |p| "#{p}/[0-9]*_*.rb" }
        versions = Dir[*paths].map do |filename|
          filename.split('/').last.split('_').first.to_i
        end

        unless migrated.include?(version)
          ::ActiveRecord::Base.connection.execute "INSERT INTO #{sm_table} (version) VALUES ('#{version}-#{current_plugin.id}')"
        end

        inserted = Set.new
        (versions - migrated).each do |v|
          if inserted.include?(v)
            raise "Duplicate migration #{v}. Please renumber your migrations to resolve the conflict."
          elsif v < version
            ::ActiveRecord::Base.connection.execute "INSERT INTO #{sm_table} (version) VALUES ('#{v}-#{current_plugin.id}')"
            inserted << v
          end
        end
      end

      def migrated
        @migrated_versions || load_migrated
      end

      def load_migrated
        @migrated_versions = Set.new(self.class.get_all_versions)
      end
    end

    # http://www.redmine.org/issues/28934

  end
end


module EasyProjectLoader

  CORE_PLUGINS       = %w(easy_extensions easy_hosting_services)
  MOD_PLUGINS_REGEXP = /^modification/

  def self.application_root_plugin_path
    Pathname.new(Rails.root.join('plugins', 'easyproject'))
  end

  def self.can_start?
    Rails.env.test? || ActiveRecord::Base.connection.table_exists?('settings')
  rescue ActiveRecord::NoDatabaseError
    false
  end

  def self.init!
    if !can_start?
      $stderr.puts "The application cannot start because the Redmine is not migrated!\n" +
                     "Please run `bundle exec rake db:migrate RAILS_ENV=production`\n" +
                     "and than `bundle exec rake easyproject:install RAILS_ENV=production`"
      return
    end

    #::I18n.load_path += Dir["#{Rails.root}/config/locales/*"]

    Mail.eager_autoload!
    require_relative './lib/easyproject/easy_uglifier_compressor'
    ActionView::Template.unregister_template_handler :ruby
    Sprockets.register_compressor 'application/javascript', :easy_uglifier, Sprockets::EasyUglifierCompressor

    Rails.application.configure do
      config.assets.enabled = true
      config.assets.compile = true #!Rails.env.production?
      config.assets.digest  = Rails.env.production?
      # config.assets.debug = true
      if Rails.env.production?
        config.assets.compress       = true
        config.assets.js_compressor  = Sprockets::EasyUglifierCompressor.new(harmony: true)
        config.assets.css_compressor = :sass
      end
      config.serve_static_files = true
    end

    # the entry was already removed https://github.com/getsentry/raven-ruby/issues/701
    ActionMailer::DeliveryJob.class_eval do
      discard_on ::ActiveJob::DeserializationError
    end

    CORE_PLUGINS.each do |core_plugin|
      load_plugin_init(application_root_plugin_path.join('easy_plugins', core_plugin))
    end

    EasyHostingPlugin.check_activations if EasyHostingPlugin.table_exists?

    load_all_plugins

    ActiveSupport.run_load_hooks(:easyproject, self)
  end

  def self.load_all_plugins
    easy_helpers_plugins = Dir.glob(application_root_plugin_path.join('easy_helpers', '*')).sort
    easy_plugins         = []; redmine_plugins = []; modifications_plugins = []

    (Dir.glob(application_root_plugin_path.join('easy_plugins', '*')).sort - [application_root_plugin_path.to_s]).each do |p|
      next unless File.directory?(p)
      case File.basename(p)
      when MOD_PLUGINS_REGEXP, 'easy_project_com', 'easy_redmine'
        modifications_plugins << p
      else
        easy_plugins << p
      end
    end

    Dir.glob(Rails.root.join('plugins', '*')).sort.each do |p|
      next unless File.directory?(p)
      case File.basename(p)
      when MOD_PLUGINS_REGEXP
        modifications_plugins << p
      else
        redmine_plugins << p
      end
    end

    all_plugins = easy_helpers_plugins + easy_plugins + redmine_plugins + modifications_plugins

    all_plugins.each do |plugin_path|
      load_plugin_init(plugin_path)
    end

    if Rails.env.test?
      require application_root_plugin_path.join('easy_plugins', 'easy_extensions', 'lib', 'easy_extensions', 'tests', 'easy_test_prepare')
      EasyExtensions::Tests::EasyTestPrepare.prepare!
    end
  end

  def self.load_plugin_init(plugin_path)
    plugin_path = Pathname.new(plugin_path)
    return if !plugin_path.exist?

    if (initializer = plugin_path.join('init.rb')) && File.file?(initializer)
      require initializer
      if Rails.env.test? && File.exists?((tests = File.expand_path('../test', initializer)))
        FactoryBot.definition_file_paths << File.join(tests, 'factories') unless $ryspec
        lib_support = File.join(tests, 'spec/support')
        RSpec.configure { |c| c.requires.concat Dir.glob("#{lib_support}/**/*.rb") } if File.exists?(lib_support)
      end
    end
  end
end

EasyProjectLoader.init!

class EasyLoadPath < Array
  def +(arr)
    EasyLoadPath.new(super.uniq)
  end
end

I18n.load_path = EasyLoadPath.new(I18n.load_path)
