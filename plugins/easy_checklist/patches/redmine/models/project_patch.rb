module EasyChecklistPlugin
  module ProjectPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        before_create :add_default_templates

        has_and_belongs_to_many :easy_checklist_templates,
          :join_table => 'projects_easy_checklists',
          :foreign_key => 'project_id',
          :association_foreign_key => 'easy_checklist_id',
          :class_name => 'EasyChecklistTemplate'

        private

        def add_default_templates
          if enabled_module('easy_checklists') && !self.easy_is_easy_template?
            EasyChecklistTemplate.where(is_default_for_new_projects: true).each do |checklist|
              easy_checklist_templates << checklist unless easy_checklist_templates.include?(checklist)
            end
          end
        end

        def copy_easy_checklists(source_project)
          source_project.easy_checklist_templates.each do |checklist|
            easy_checklist_templates << checklist unless easy_checklist_templates.include?(checklist)
          end
        end
      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
RedmineExtensions::PatchManager.register_model_patch 'Project', 'EasyChecklistPlugin::ProjectPatch'
