module EasyExtensions
  class MigrationContext < ActiveRecord::MigrationContext
    def up(target_version = nil)
      selected_migrations = if block_given?
                              migrations.select { |m| yield m }
                            else
                              migrations
                            end
      DataMigrator.new(:up, selected_migrations, target_version).migrate
    end

    def down(target_version = nil)
      selected_migrations = if block_given?
                              migrations.select { |m| yield m }
                            else
                              migrations
                            end
      DataMigrator.new(:down, selected_migrations, target_version).migrate
    end

    def run(direction, target_version)
      DataMigrator.new(direction, migrations, target_version).run
    end

    def open
      DataMigrator.new(:up, migrations, nil)
    end
  end

  class DataMigrator < ActiveRecord::Migrator
    # We need to be able to set the 'current' plugin being migrated.
    cattr_accessor :current_plugin

    class << self
      def schema_migrations_table_name
        SchemaEasyDataMigration.table_name
      end

      def get_all_versions(plugin = current_plugin)
        @all_versions                 ||= {}
        @all_versions[plugin.id.to_s] ||= begin
          sm_table            = schema_migrations_table_name
          migration_versions  = SchemaEasyDataMigration.connection.select_rows("SELECT plugin, version FROM #{sm_table}")
          versions_by_plugins = migration_versions.inject({}) do |acc, v|
            acc[v[0]] ||= []; acc[v[0]] << v[1]; acc
          end
          @all_versions       = versions_by_plugins.transform_values! { |versions| versions.map!(&:to_i).sort! }
          @all_versions[plugin.id.to_s] || []
        end
      end

      def assume_migrated_upto_version(version)
        sm_table         = schema_migrations_table_name
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

      # Runs the migrations from a plugin, up (or down) to the version given
      def migrate_plugin(plugin, version)
        self.current_plugin = plugin
        if File.directory?(plugin.migration_easy_data_directory)
          unless SchemaEasyDataMigration.table_exists?
            SchemaEasyDataMigration.create_table
            SchemaEasyDataMigration.reset_column_information
          end
          return if current_version(plugin) == version
          MigrationContext.new(plugin.migration_easy_data_directory).migrate(version)
        end
      end

      def current_version(plugin = current_plugin)
        get_all_versions(plugin).last || 0
      end
    end

    def initialize(direction, migrations, target_version = nil)
      @direction         = direction
      @target_version    = target_version
      @migrated_versions = nil
      @migrations        = migrations

      validate(@migrations)

      SchemaEasyDataMigration.create_table
    end

    def migrated
      @migrated_versions || load_migrated
    end

    def load_migrated
      @migrated_versions = Set.new(self.class.get_all_versions)
    end

    def record_version_state_after_migrating(version)
      if down?
        migrated.delete(version)
        SchemaEasyDataMigration.where(:plugin => current_plugin.id, :version => version.to_s).delete_all
      else
        migrated << version
        SchemaEasyDataMigration.create!(:plugin => current_plugin.id, :version => version.to_s)
      end
    end
  end

  class EasyDataMigration < ActiveRecord::Migration[4.2]

  end

  class SchemaEasyDataMigration < ActiveRecord::Base

    def self.table_name
      "#{SchemaEasyDataMigration.table_name_prefix}schema_easy_data_migrations#{SchemaEasyDataMigration.table_name_suffix}"
    end

    def self.index_name
      "#{SchemaEasyDataMigration.table_name_prefix}unique_schema_easy_data_migrations#{SchemaEasyDataMigration.table_name_suffix}"
    end

    def self.create_table(limit = nil)
      unless connection.table_exists?(table_name)
        version_options = { null: false }

        connection.create_table(table_name, primary_key: %i[plugin version]) do |t|
          t.column :plugin, :string
          t.column :version, :string, version_options
          t.column :options, :text
        end
      end
    end

    def self.drop_table
      if connection.table_exists?(table_name)
        connection.remove_index table_name, name: index_name
        connection.drop_table(table_name)
      end
    end
  end
end
