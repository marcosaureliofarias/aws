module Diagrams
  module EntityAttributeHelperPatch
    def self.included(base)
      base.class_eval do
        def format_html_diagram_attribute(entity_class, attribute, unformatted_value, options={})
          if (attribute.is_a?(EasyQueryColumn)) && options[:entity]
            @diagram_formatter ||= DiagramFormatter.new(self)
            @diagram_formatter.format_column(attribute, options[:entity])
          else
            format_html_default_entity_attribute(attribute, unformatted_value, options)
          end
        end
      end
    end
  end
end

RedmineExtensions::PatchManager.register_helper_patch 'EntityAttributeHelper', 'Diagrams::EntityAttributeHelperPatch', if: proc { Redmine::Plugin.installed? :easy_extensions }
