module EasyPatch
  module RedmineInfoPatch

    def self.included(base)

      base.extend(ClassMethods)
      base.class_eval do

        class << self

          alias_method_chain :app_name, :easy_extensions
          alias_method_chain :url, :easy_extensions
          alias_method_chain :help_url, :easy_extensions
          alias_method_chain :environment, :easy_extensions
          alias_method_chain :versioned_name, :easy_extensions

          def database_encoding
            conn = ActiveRecord::Base.connection
            if Redmine::Database.postgresql?
              conn.select_values('SHOW SERVER_ENCODING;').join + ' / ' + conn.select_values('SHOW LC_COLLATE;').join
            else
              conn.select_rows('SELECT @@character_set_database, @@collation_database;').flatten.join(' / ')
            end
          end

        end
      end
    end

    module ClassMethods
      def app_name_with_easy_extensions;
        EasyExtensions::EasyProjectSettings.app_name
      end

      def url_with_easy_extensions;
        EasyExtensions::EasyProjectSettings.app_link
      end

      def help_url_with_easy_extensions
        ''
      end

      def versioned_name_with_easy_extensions
        "#{app_name} #{EasyExtensions.full_version}"
      end

      def environment_with_easy_extensions
        env = "#{EasyExtensions::EasyProjectSettings.app_name}:\n"
        env << "  %-30s %s\n" % ['Platform version', EasyExtensions.platform_version]
        env << "  %-30s %s\n" % ['Build version', EasyExtensions.build_version]
        env << "  %-30s %s\n" % ['Full version', EasyExtensions.full_version]
        env << environment_without_easy_extensions
        env << "\nRys plugins:\n"

        s = RysManagement.all.map do |rys_plugin|
          [rys_plugin.name, "#{Gem.loaded_specs[rys_plugin.rys_id]&.version.to_s}"]
        end
        env << s.map { |info| "  %-30s %s" % info }.join("\n") + "\n"

        env << "\nServer:\n"
        s = [
            ['Current datetime', "#{User.current.user_time_in_zone}"],
            ['Server datetime', "#{Time.now}"]
        ]
        begin
          s << ['Database encoding', database_encoding]
        rescue ::ActiveRecord::StatementInvalid
          # not supported
        end

        env << s.map { |info| "  %-30s %s" % info }.join("\n") + "\n"
        env
      end
    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Info', 'EasyPatch::RedmineInfoPatch'
