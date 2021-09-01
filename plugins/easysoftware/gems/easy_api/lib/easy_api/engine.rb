require 'rys'

module EasyApi
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'easy_api'

    initializer 'easy_api.load', after: :load_config_initializers do
      # Core things should be on the core
      # But I have decided it will be here
      if Redmine::Plugin.installed?(:easy_extensions) && EasyQuery.table_exists? && !Redmine::Plugin.installation?
        config.to_prepare {
          EasyApi::Engine.load_api
        }
      end
    end

    def self.load_api
      api_directories = []

      # Find API from redmine plugins
      Redmine::Plugin.registered_plugins.each do |id, plugin|
        api_dir = File.join(plugin.directory, 'api')

        if Dir.exists?(api_dir)
          api_directories << api_dir
        end
      end

      # Find API from rys plugins
      RysManagement.all(systemic: true) do |engine|
        api_dir = File.join(engine.root, 'api')

        if Dir.exists?(api_dir)
          api_directories << api_dir
        end
      end

      # To prevent glob on "/**/*.rb"
      if api_directories.empty?
        return
      end

      # Load graphql_definitions
      # Temporarily enable autoload in API folders
      with_autoload_paths(api_directories) do
        patern = "{#{api_directories.join(',')}}/**/*.rb"
        Dir.glob(patern) {|f| require_or_load(f) }
      end
    end

    def self.with_autoload_paths(paths)
      origin_paths = ActiveSupport::Dependencies.autoload_paths
      ActiveSupport::Dependencies.autoload_paths += paths
      yield
    ensure
      ActiveSupport::Dependencies.autoload_paths = origin_paths
    end

  end
end
