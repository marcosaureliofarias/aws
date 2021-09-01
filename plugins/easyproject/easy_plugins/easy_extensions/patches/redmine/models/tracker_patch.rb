module EasyPatch
  module TrackerPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        Tracker.send(:remove_const, 'CORE_FIELDS_UNDISABLABLE')
        Tracker.send(:const_set, 'CORE_FIELDS_UNDISABLABLE', %w(author_id project_id tracker_id subject priority_id is_private).freeze)
        old_core_fields = Tracker::CORE_FIELDS
        Tracker.send(:remove_const, 'CORE_FIELDS')
        Tracker.send(:const_set, 'CORE_FIELDS', (old_core_fields + ['easy_email_to', 'easy_email_cc']).freeze)
        Tracker.send(:remove_const, 'CORE_FIELDS_ALL')
        Tracker.send(:const_set, 'CORE_FIELDS_ALL', (Tracker::CORE_FIELDS_UNDISABLABLE + Tracker::CORE_FIELDS).freeze)

        acts_as_easy_translate

        scope :with_easy_distributed_tasks, lambda { where(:easy_distributed_tasks => true) }

        safe_attributes 'easy_icon',
                        'easy_external_id',
                        'easy_distributed_tasks',
                        'easy_do_not_allow_close_if_no_attachments',
                        'easy_do_not_allow_close_if_subtasks_opened',
                        'easy_send_invitation',
                        'internal_name',
                        'is_in_chlog',
                        'easy_color_scheme',
                        'reorder_to_position'

        def custom_field_mapping_data(tracker_to)
          return {} if tracker_to.blank?

          data = {}
          custom_fields.each do |cf_from|
            data[cf_from] = tracker_to.custom_fields.select { |cf_to| cf_from.field_format == cf_to.field_format }
          end
          data
        end

        def move_issues(tracker, cf_map = {})
          Mailer.with_deliveries(false) do
            tracker_project_ids = tracker.project_ids
            transaction do
              self.issues.preload(:project, :custom_values).find_each(:batch_size => 50) do |issue|
                tracker_project_ids << issue.project_id unless tracker_project_ids.include?(issue.project_id)
                project = issue.project
                issue.custom_values.each do |cv|
                  if cf_map[cv.custom_field_id]
                    unless project.issue_custom_field_ids.include?(cf_map[cv.custom_field_id])
                      project.issue_custom_field_ids << cf_map[cv.custom_field_id]
                      project.save
                    end
                    cv.custom_field_id = cf_map[cv.custom_field_id]
                    cv.save
                  else
                    cv.destroy
                  end
                end
              end
              self.issues.update_all(:tracker_id => tracker.id)
              tracker.project_ids = tracker_project_ids.uniq
              tracker.save(:validate => false)
            end
          end
        end

      end
    end

    module InstanceMethods


    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Tracker', 'EasyPatch::TrackerPatch'
