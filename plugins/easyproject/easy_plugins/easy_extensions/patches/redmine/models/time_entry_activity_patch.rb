module EasyPatch
  module TimeEntryActivityPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        acts_as_easy_translate

        has_many :project_activity_roles, class_name: 'ProjectActivityRole', foreign_key: 'activity_id', dependent: :delete_all
        has_and_belongs_to_many :activity_roles_projects, join_table: 'projects_activity_roles', foreign_key: 'activity_id', class_name: 'Project'
        has_and_belongs_to_many :projects, join_table: 'projects_activities', foreign_key: 'activity_id', validate: false

        after_destroy :delete_time_entry_activities

        scope :like, -> (arg) do
          if arg.blank?
            where(nil)
          else
            where(Redmine::Database.like("#{TimeEntryActivity.table_name}.name", '?'), "%#{arg}%")
          end
        end

        def form_partial
          'enumerations/form_with_projects'
        end

        private

        def delete_time_entry_activities
          self.class.connection.execute("DELETE FROM #{ProjectActivity.table_name} WHERE activity_id = #{self.id}")
        end

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'TimeEntryActivity', 'EasyPatch::TimeEntryActivityPatch', after: 'Enumeration'
