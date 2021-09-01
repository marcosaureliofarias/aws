module EasyPrintableTemplates
  module IssuesHelperPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        def link_to_issue_print(options = {})
          { :controller => 'easy_printable_templates', :action => 'template_chooser', :entity_type => 'Issue', :entity_id => @issue, :back_url => original_url }.merge(options)
        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end
  end
end

RedmineExtensions::PatchManager.register_helper_patch 'IssuesHelper', 'EasyPrintableTemplates::IssuesHelperPatch'
