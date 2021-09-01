require 'active_record/fixtures'
require 'database_cleaner'

if Rails.env.test?
  require 'factory_bot_rails'
  FactoryGirl = FactoryBot
end

module EasyExtensions
  module Tests

    class AllowedFailures
      class_attribute :test_names
      self.test_names = {}

      def self.register(names, options = {})
        options.assert_valid_keys(:message, :raise)
        Array(names).each do |name|
          test_names[name.to_s] = options
        end
      end
    end

    module FixtureSetPatch
      extend ActiveSupport::Concern

      included do

        def read_fixture_files_with_easy_tests(path)
          yaml_files = (Dir["#{path}/{**,*}/*.yml"] + Dir["#{path}.yml"]).select { |f|
            ::File.file?(f)
          }

          yaml_files.each_with_object({}) do |file, fixtures|
            ::ActiveRecord::FixtureSet::File.open(file) do |fh|
              fh.each do |fixture_name, row|
                fixtures[fixture_name] = ::ActiveRecord::Fixture.new(row, model_class)
              end
            end
          end
        end

        alias_method_chain :read_fixture_files, :easy_tests

      end
    end
    ::ActiveRecord::FixtureSet.include(FixtureSetPatch)


    module SchemaPatch

      def self.included(base)
        base.class_eval do
          def define_with_easyproject(info, &block)
            define_without_easyproject(info, &block)

            unless info[:version].blank?
              Redmine::Plugin.all.each do |p|
                Redmine::Plugin::Migrator.current_plugin = p
                Redmine::Plugin::Migrator.assume_migrated_upto_version(info[:version])
              end
            end
          end

          alias_method_chain :define, :easyproject
        end
      end

    end
    ActiveRecord::Schema.include(SchemaPatch)

    class FixturesSet
      attr_accessor :path, :fixtures

      def initialize(path, fixtures)
        self.path, self.fixtures = path, fixtures
      end

      def create
        ActiveRecord::FixtureSet.create_fixtures(path, fixtures)
      end
    end

    class EasyTestPrepare

      @prepares = []

      class << self
        attr_reader :prepares
        private :new

        def def_field(*names)
          class_eval do
            names.each do |name|
              define_method(name) do |*args|
                args.empty? ? instance_variable_get("@#{name}") : instance_variable_set("@#{name}", *args)
              end
            end
          end
        end
      end

      def_field :directory

      def self.needs_migration?
        needs = ActiveRecord::Base.connection.migration_context.needs_migration?
        Redmine::Plugin.all.each do |p|
          Redmine::Plugin::Migrator.current_plugin = p
          needs                                    = needs || Redmine::Plugin::Migrator.needs_migration?
        end
        needs
      end

      def self.load_schema_if_pending!
        if needs_migration?
          ActiveRecord::Tasks::DatabaseTasks.load_schema_current
        end
      end

      def self.maintain_test_schema! # :nodoc:
        if ActiveRecord::Base.maintain_test_schema
          ActiveRecord::Migration.suppress_messages { load_schema_if_pending! }
          ActiveRecord::Migration.check_pending!
        end
      end

      def self.persist_tables=(tables)
        raise ArgumentError, 'Tables has to be array of tables' unless tables.is_a?(Array)
        @persist_tables = tables
      end

      def self.persist_tables
        @persist_tables ||= ['easy_settings', 'rys_features', 'settings'] + schema_tables
      end

      def self.schema_tables
        ['schema_migrations', 'schema_easy_data_migrations']
      end

      def self.to_prepare(name = nil, &block)
        p = new(name)
        p.instance_eval(&block)
        @prepares << p
      end

      def self.prepare!
        maintain_test_schema!
        # ActiveRecord::Migration.maintain_test_schema! #TODO: write own!
        DatabaseCleaner.clean_with(:deletion, { except: schema_tables })
        @prepares.each { |prep| prep.prepare! }
      end

      def self.load_default_fixtures
        @prepares.each { |prep| prep.load_default_fixtures }
      end

      def initialize(name)
        @name = name.to_s if name
      end

      def prepare!
        persist_fixture_sets.each do |fix_set|
          fix_set.create
          self.class.persist_tables |= fix_set.fixtures.map { |table| table.to_s }
        end
        rm_list = redmine_settings.collect { |name, value| { name: name, value: value } }
        Setting.transaction do
          Setting.create!(rm_list)
        end if rm_list.any?

        es_list = easy_settings.collect { |name, value| { name: name, value: value } }
        EasySetting.transaction do
          EasySetting.create!(es_list)
        end if es_list.any?
      end

      def default_fixture_path
        raise 'Please set the directory variable if you want to use default paths' unless self.directory
        Rails.root.join('plugins', 'easyproject', 'easy_plugins', '*', 'test', 'fixtures')
      end

      def persist_fixture_sets
        @persist_fixture_sets ||= []
      end

      def default_fixture_sets
        @default_fixture_sets ||= []
      end

      def persist_table_fixtures(tables, path = nil)
        path ||= self.default_fixture_path

        persist_fixture_sets << FixturesSet.new(path, tables)
      end

      def default_fixtures(fixtures, path = nil)
        path ||= self.default_fixture_path

        default_fixture_sets << FixturesSet.new(path, fixtures)
      end

      def load_default_fixtures
        default_fixture_sets.each do |fix_set|
          fix_set.create
        end
      end

      def redmine_settings
        @redmine_settings ||= {}
      end

      def easy_settings
        @easy_settings ||= {}
      end

      def easy_settings_from_yml(yaml)
        yaml.each do |name, setting|
          easy_settings[name] = setting['default']
        end
      end

    end

  end
end
