module EasyPatch
  module IssueStatusPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do
        validates_length_of :description, maximum: 255

        scope :open, lambda { where(is_closed: false) }
        scope :closed, lambda { where(is_closed: true) }

        after_create :clear_status_reports_cache
        after_destroy :clear_status_reports_cache

        acts_as_easy_translate

        safe_attributes 'description', 'easy_color_scheme', 'reorder_to_position', 'easy_external_id'

        def replace_with(new_issue_status_id)
          Issue.where(status_id: self.id).update_all(status_id: new_issue_status_id)
          Tracker.where(default_status_id: self.id).update_all(default_status_id: new_issue_status_id)
        end

        def clear_status_reports_cache
          EasyReportSetting.destroy_all
        end

      end
    end

    module ClassMethods
    end

    module InstanceMethods
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'IssueStatus', 'EasyPatch::IssueStatusPatch'
