module Diagrams
  module EasyQueryButtonsHelperPatch
    def self.included(base)
      base.class_eval do
        def diagram_query_additional_ending_buttons(entity, options = {})
          @diagram_formatter ||= DiagramFormatter.new(self)
          @diagram_formatter.ending_buttons(entity)
        end
      end
    end
  end
end

RedmineExtensions::PatchManager.register_helper_patch 'EasyQueryButtonsHelper', 'Diagrams::EasyQueryButtonsHelperPatch', if: proc { Redmine::Plugin.installed? :easy_extensions }
