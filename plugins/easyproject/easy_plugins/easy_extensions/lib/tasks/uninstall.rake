namespace :easyproject do
  namespace :uninstall do
    desc <<-END_DESC
    Uninstall plugins specified in `LIST` parameter

    Example:
      bundle exec rake easyproject:uninstall:plugins LIST=easy_calendar RAILS_ENV=production
      Force usage:
      bundle exec rake easyproject:uninstall:plugins[1] LIST=easy_calendar RAILS_ENV=production
    END_DESC

    task :plugins, [:force] => :environment do |t, args|
      puts ''

      only_list = ENV['LIST'].to_s.gsub(/\s/, '').split(',')
      if ENV['N']
        plugins = get_plugins_list.reject { |plugin| only_list.include?(plugin.name) }
      else
        plugins = get_plugins_list.select { |plugin| only_list.include?(plugin.name) }
      end
      uninstalled_plugins = []
      plugins.each do |plugin|
        unless args[:force]
          print "Do you like to uninstall plugin #{plugin}? [y/N]"
          STDOUT.flush
          next unless STDIN.gets.match(/^y$/i)
        end
        plugin.uninstall
        uninstalled_plugins << plugin
      end
      Rake::Task['db:schema:dump'].invoke
      uninstalled_plugins.each(&:delete)
    end

    desc <<-END_DESC
    Uninstall all easy plugins

    Example:
      bundle exec rake easyproject:uninstall:all_plugins RAILS_ENV=production
    END_DESC

    task :all_plugins, [:force] => :environment do |t, args|
      puts ''

      uninstalled_plugins = []
      get_plugins_list.each do |plugin|
        unless args[:force]
          print "Do you like to uninstall plugin #{plugin}? [y/N]"
          STDOUT.flush
          next unless STDIN.gets.match(/^y$/i)
        end
        plugin.uninstall
        uninstalled_plugins << plugin
      end
      Rake::Task['db:schema:dump'].invoke
      uninstalled_plugins.each(&:delete)
    end

    task :plugin => :environment do
      ENV['VERSION'] = '0'
      plugin         = get_plugins_list.detect { |p| p.name == ENV['NAME'] }
      return if plugin.nil?

      plugin.uninstall

      Rake::Task['db:schema:dump'].invoke

      plugin.delete

      puts "\n Plugin #{plugin} uninstalled. \n"
      puts ''
    end

    def get_plugins_list
      #   Rails.application.config.i18n.load_path = []
      #   ::I18n.load_path = []
      problematic_easy_plugins = %w(easy_knowledge easy_computed_custom_fields easy_external_storages)
      forbidden_easy_plugins   = %w(easy_extensions easy_xml_helper easy_redmine easy_job)
      plugins                  = []; skipping = (problematic_easy_plugins + forbidden_easy_plugins)
      # Collect redmine plugins except `easyproject`
      (Dir[File.join(Rails.root, 'plugins', '*')] - [EasyExtensions::PATH_TO_EASYPROJECT_ROOT]).sort.each do |plugin|
        if File.directory?(plugin) && File.exists?(File.join(plugin, 'init.rb'))
          plugin_name = File.basename(plugin)
          next if skipping.include?(plugin_name)
          plugins << EasyUninstaller::RedminePlugin.new(plugin_name)
        end
      end
      # Collect easy plugins except `problematics`
      Dir[File.join(EasyExtensions::PATH_TO_EASYPROJECT_ROOT, 'easy_plugins', '*')].sort.each do |plugin|
        plugin_name = File.basename(plugin)
        next if skipping.include?(plugin_name) || plugin_name.start_with?("modification")
        plugins << EasyUninstaller::EasyPlugin.new(plugin_name)
      end
      # move problems plugins to end of list
      problematic_easy_plugins.each { |plugin_name| plugins << EasyUninstaller::EasyPlugin.new(plugin_name) }
      plugins
    end

    module EasyUninstaller
      class Plugin

        attr_reader :name, :path

        def initialize(name)
          @name = name
        end

        alias_method :to_s, :name

        def uninstall
          Redmine::Plugin.migrate_easy_data(name, 0)
          resolve_dependencies
          Redmine::Plugin.migrate(name, 0)
        end

        def delete
          ::I18n.load_path -= Dir[@path.join('config', 'locales', '*')]
          FileUtils.rm_rf(path)
          FileUtils.rm_rf(File.join(Rails.public_path, 'plugin_assets', name))
        end

        def resolve_dependencies
          uninstall_dependency_klasses(EasyQuery, :entity)
          uninstall_dependency_klasses(EasyPageModule, :category_name)
          uninstall_dependency_klasses(CustomField, :type_name)
          uninstall_dependency_klasses(EasyRakeTask, :execute)
        end

        private

        def uninstall_dependency_klasses(parent_klass, instance_method)
          parent_klass.descendants.each do |klass|
            begin
              klass_path = Pathname.new(klass.instance_method(instance_method).source_location.first)
              if klass_path.to_s.starts_with?(path.to_s)
                if klass.unscoped.exists?
                  puts "  ...destroy all #{klass.name.pluralize}"
                  klass.unscoped.destroy_all
                end
              end
            rescue StandardError => e
              puts "#{klass.name} can not be destroyed! (#{e.message})"
            end
          end
        end

      end

      class EasyPlugin < Plugin
        def initialize(name)
          super
          @path = Pathname.new(File.join(EasyExtensions::PATH_TO_EASYPROJECT_ROOT, 'easy_plugins', name))
        end

      end

      class RedminePlugin < Plugin
        def initialize(name)
          super
          @path = Rails.root.join('plugins', name)
        end
      end
    end

  end
end
