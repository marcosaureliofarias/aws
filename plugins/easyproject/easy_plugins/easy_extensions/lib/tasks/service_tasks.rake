namespace :easyproject do
  namespace :service_tasks do

    desc <<-END_DESC

    Example:
      bundle exec rake easyproject:service_tasks:process_all RAILS_ENV=production --trace
    END_DESC

    task :process_all => [
        :issues_rebuild,
        :projects_rebuild
    ]

    desc <<-END_DESC
    Runs all data migrations
    END_DESC
    task :data_migrate => :environment do
      name           = ENV['NAME']
      version        = nil
      version_string = ENV['VERSION']
      if version_string
        if version_string =~ /^\d+$/
          version = version_string.to_i
          if name.nil?
            abort "The VERSION argument requires a plugin NAME."
          end
        else
          abort "Invalid VERSION #{version_string} given."
        end
      end

      begin
        Redmine::Plugin.migrate_easy_data(name, version)
      rescue Redmine::PluginNotFound
        abort "Plugin #{name} was not found."
      end
    end

    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:service_tasks:projects_rebuild RAILS_ENV=production --trace
    END_DESC
    task :projects_rebuild => :environment do
      Project.rebuild!
    end

    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:service_tasks:issues_rebuild RAILS_ENV=production --trace
    END_DESC
    task :issues_rebuild => :environment do
      Issue.rebuild!
    end

    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:service_tasks:clear_cache RAILS_ENV=production --trace
    END_DESC
    task :clear_cache => :environment do
      cache_store = ActionController::Base.cache_store
      if cache_store.present? && cache_store.respond_to?(:cache_path) && File.exist?(cache_store.cache_path)
        begin
          ActionController::Base.cache_store.clear
        rescue
          pp "Cache on #{ActionController::Base.cache_store.cache_path} was not deleted. You should do it manually."
        end
      end

    end

    # Translate the language names
    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:service_tasks:invoking_cache RAILS_ENV=production --trace
    END_DESC
    task :invoking_cache => :environment do
      unless ActionController::Base.cache_store.exist? "i18n/languages_options"
        include Redmine::I18n
        languages_options
      end

      require 'easy_extensions/easy_assets'
      EasyExtensions::EasyAssets.mirror_assets
      EasyExtensions::EasyAssets.mirror_easy_images
    end

    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:service_tasks:migrate_to_new_ruby RAILS_ENV=production --trace
    END_DESC
    task :migrate_to_new_ruby => :environment do
      require 'easy_extensions/yaml_encoder'
      y = YamlEncoder.new
      y.repair
    end

    desc <<-END_DESC
    Example:
      bundle exec rake easyproject:service_tasks:set_default_collation RAILS_ENV=production --trace
    END_DESC
    task :set_default_collation => :environment do
      connection = ActiveRecord::Base.connection
      if connection.adapter_name =~ /mysql/i
        database_encoding, database_collation = connection.select_one('SELECT default_character_set_name, default_collation_name FROM information_schema.SCHEMATA WHERE schema_name = DATABASE()').values

        sql = <<-SQL
        SELECT
          t.table_name, 
          t.table_collation, 
          ccsa.character_set_name as table_encoding 
        FROM
          information_schema.TABLES t 
          JOIN information_schema.COLLATION_CHARACTER_SET_APPLICABILITY ccsa ON ccsa.collation_name = t.table_collation 
        WHERE
          t.table_schema = DATABASE()
          AND t.table_collation != '#{database_collation}'
        SQL

        connection.select_all(sql).each do |row|
          table_name, table_collation, table_encoding = row.values
          unless table_collation == database_collation && table_encoding == database_encoding
            pp "Change table #{table_name} to encoding #{database_encoding} with collation #{database_collation}"
            connection.execute "ALTER TABLE #{table_name} CONVERT TO CHARACTER SET '#{database_encoding}' COLLATE '#{database_collation}'"
          end
        end
      end
    end


  end
end
