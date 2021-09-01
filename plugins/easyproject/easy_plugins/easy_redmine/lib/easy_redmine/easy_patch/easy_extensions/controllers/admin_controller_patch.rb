module EasyRedmine
  module AdminControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        helper :projects, :easy_query
        include ProjectsHelper

        alias_method_chain :manage_plugins, :easy_redmine

      end
    end

    module InstanceMethods

      def manage_plugins_with_easy_redmine
        @disabled_plugins = Redmine::Plugin.disabled_plugins.values.select { |p| p.should_be_disabled != false && p.visible != false }.sort_by { |p| p.name.is_a?(Symbol) ? l(p.name) : p.name }
        @active_plugins = Redmine::Plugin.all(only_visible: true, without_disabled: true).select { |p| p.should_be_disabled != false }.sort_by { |p| p.name.is_a?(Symbol) ? l(p.name) : p.name }
        @plugin_bundles = Redmine::Plugin.bundled_plugin_ids.keys
        @segregated_plugins_hash = {}

        @plugin_bundles.each do |bundle|
          @segregated_plugins_hash.merge!({bundle => {active: [], disabled: []}})
          Redmine::Plugin.plugins_in_category(bundle, only_visible: true).each do |plugin|
            if plugin.disabled?
              @segregated_plugins_hash[bundle][:disabled] << plugin
            else
              @segregated_plugins_hash[bundle][:active] << plugin
            end
          end
          @segregated_plugins_hash[bundle] = @segregated_plugins_hash[bundle].inject({}) do |hash, (k, v)|
            hash.merge(k.to_sym => v.sort_by { |p| p.name.is_a?(Symbol) ? l(p.name) : p.name })
          end
        end

        @segregated_plugins_hash.merge!({other: {active: [], disabled: []}})

        Redmine::Plugin.all(only_visible: true).select { |p| p.belongs_to_categories.empty? && p.should_be_disabled? }.each do |plugin|
          if plugin.disabled?
            @segregated_plugins_hash[:other][:disabled] << plugin
          else
            @segregated_plugins_hash[:other][:active] << plugin
          end
        end
        @segregated_plugins_hash[:other] = @segregated_plugins_hash[:other].inject({}) do |hash, (k, v)|
          hash.merge(k.to_sym => v.sort_by { |p| p.name.is_a?(Symbol) ? l(p.name) : p.name })
        end

        render 'manage_plugins'
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'AdminController', 'EasyRedmine::AdminControllerPatch'
