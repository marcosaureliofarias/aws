require 'rys'

module RysManagement
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    config.before_configuration do
      Rys::PluginsManagement.all do |plugin|
        plugin.parent&.include(RysManagement::PluginConfig)
      end
    end

    generators do
      Rys::Hook.register('rys.plugin_generator.after_generated') do |generator|
        source = RysManagement::Engine.root.join('lib/generators/rys_management/templates/plugin_setting.html.erb')
        target = 'app/views/rys_management/plugins/_%underscored_name%.html.erb'

        generator.template source, target
      end
    end

    initializer 'rys_management.setup' do
      # Custom initializer
    end

    lib_dependency_files do
      ['rys_management/plugin_delegator']
    end

  end
end
