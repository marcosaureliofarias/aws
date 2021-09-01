module SearchInAdministration
  class EasyAdministrationSearch
    def initialize(helper)
      @helper = helper
    end

    def settings
      @settings ||= []
    end

    def sorted_settings
      settings.sort_by{ |s| s[:label] }
    end

    def fill_settings
      settings_from_yml.each do |path, options|
        options.values.each do |options|
          label_prefix = label_prefix(options, path)
          options['labels'].each do |label|
            next if should_skip_setting(options)

            add_setting(label_prefix + label(label), @helper.send(path, options['params']))
          end
        end
      end
      fill_settings_with_plugins
      fill_settings_with_ryses
      add_setting(label(:label_information), '/admin/info')
    end

    private

    def add_setting(label, jump_url)
      settings << { label: label, jump_url: jump_url }
    end

    def label(l)
      @helper.l(l)
    end

    def label_prefix(options, path)
      return '' unless options.key? 'label_tab_name'

      label_prefix = label('label_settings')
      label_prefix += " > "
      label_prefix += label(options['label_tab_name'])
      add_setting(label_prefix, @helper.send(path, options['params']))

      label_prefix += " > "
      label_prefix
    end

    def label_settings_of_rys_or_plugin
      label_settings = " - "
      label_settings += label('label_settings')
      label_settings
    end

    def activated_plugins
      @activated_plugins ||= Redmine::Plugin.all(without_disabled: true).map { |plugin| plugin.id.to_s }
    end

    def base_files
      ['general', 'sidebar']
    end

    def settings_from_yml
      yml_settings = {}
      dir_path = File.expand_path(File.join(File.dirname(__FILE__), 'easy_search_settings/*.yml'))
      files_path = Dir.glob(dir_path)

      files_path.each do |path|
        file_name = File.basename(path, ".yml")
        next unless (activated_plugins + base_files).include?(file_name)
        yml_settings.merge!(YAML.load(File.read(path)))
      end
      yml_settings
    end

    def fill_settings_with_plugins
      plugins = Redmine::Plugin.all(only_visible: true)
      plugins.each do |plugin|
        next unless plugin.configurable?

        plugin_name = plugin.name.is_a?(Symbol) ? @helper.l(plugin.name) : plugin.name
        plugin_name_with_settings = plugin_name + label_settings_of_rys_or_plugin
        add_setting(plugin_name_with_settings, @helper.plugin_settings_path(plugin))
      end
    end

    def fill_settings_with_ryses
      RysManagement.all.each do |rys|
        if rys.plugin_active?
          rys_name_with_settings = rys.name + label_settings_of_rys_or_plugin
          add_setting(rys_name_with_settings, @helper.rys_management_edit_path(rys.rys_id))
        end
      end
    end

    def should_skip_setting(options)
      return false unless options.has_key?('condition')

      condition_type = options['condition']['type']
      plugin_or_rys_name = options['condition']['name']
      if condition_type == 'redmine_plugin'
        !Redmine::Plugin.installed?(plugin_or_rys_name.to_sym)
      else
        !(RysFeatureRecord.where(name: plugin_or_rys_name, active: true).exists? && Rys::Feature.all_features.keys.include?(plugin_or_rys_name))
      end
    end
  end
end
