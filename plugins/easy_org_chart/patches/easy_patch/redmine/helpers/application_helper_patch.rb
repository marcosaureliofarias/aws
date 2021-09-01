module EasyOrgChart
  module ApplicationHelperPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def easy_org_chart_node_width
          value = EasySetting.value("easy_org_chart_node_width").strip
          value == 'auto' ? value : "#{value}px"
        end

        def easy_org_chart_node_bg_color(name)
          setting_name = "easy_org_chart_#{name}"

          Color::RGB.from_html(EasySetting.value(setting_name))
        rescue ArgumentError
          Color::RGB.from_html(EasySetting.plugin_defaults[setting_name])
        end

        def easy_org_chart_node_text_color(name)
          easy_org_chart_node_bg_color(name).brightness > 0.5 ? Color::RGB.from_html('000000') : Color::RGB.from_html('ffffff')
        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end

RedmineExtensions::PatchManager.register_helper_patch 'ApplicationHelper', 'EasyOrgChart::ApplicationHelperPatch'

