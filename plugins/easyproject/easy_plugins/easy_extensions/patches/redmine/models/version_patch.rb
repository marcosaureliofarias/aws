module EasyPatch
  module VersionPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      attr_accessor :css_shared

      base.class_eval do

        acts_as_easy_journalized :format_detail_reflection_columns => ['easy_version_category_id']

        belongs_to :easy_version_category

        scope :open_and_locked, lambda { where(status: ['open', 'locked']) }
        scope :closed, lambda { where(status: 'closed') }

        validate :validate_effective_date
        validates :project_id, :presence => true

        remove_validation :description, 'validates_length_of'

        html_fragment :description, :scrub => :strip

        after_save :create_journal

        attr_accessor :css_shared, :mass_operations_in_progress

        safe_attributes 'project_id', 'easy_version_category_id'

        alias_method_chain :deletable?, :easy_extensions

        def self.values_for_select_with_project(scope)
          scope.reorder(Arel.sql('projects.name, versions.name')).
              pluck(Arel.sql("concat(projects.name, ' - ', versions.name) as version_name, versions.id as id"))
        end

        def update_from_gantt_data(data)
          gantt_date = self.class.parse_gantt_date(data['est'])
          if gantt_date
            self.effective_date = gantt_date
          end
        end

        def update_issues_due_dates(xeffective_date_was)
          scope = self.fixed_issues
          if xeffective_date_was
            scope.joins(:status).distinct.where(["#{IssueStatus.table_name}.is_closed = ? AND #{Issue.table_name}.due_date IS NOT NULL", false]).find_each(:batch_size => 50) do |i|
              begin
                self.update_issue_due_date_with_effective_date(i, xeffective_date_was)
              rescue ActiveRecord::StaleObjectError
                i.reload
                self.update_issue_due_date_with_effective_date(i, xeffective_date_was)
              end

            end
          else
            scope.find_each(:batch_size => 50) do |i|
              begin
                self.update_issue_due_date(i)
              rescue ActiveRecord::StaleObjectError
                i.reload
                self.update_issue_due_date(i)
              end
            end
          end
        end

        def update_issue_due_date_with_effective_date(i, xeffective_date_was)
          if i.due_date && self.effective_date && xeffective_date_was
            journal    = i.init_journal(User.current)
            i.due_date = (i.due_date + (self.effective_date - xeffective_date_was).days)
            i.save
          end
        end

        def update_issue_due_date(i)
          journal    = i.init_journal(User.current)
          i.due_date = self.effective_date
          i.save
        end

        def self.update_version_from_gantt_data(data)
          v = self.find(data['id'])
          if v
            v.update_from_gantt_data(data)
            if v.save
              nil
            else
              v
            end
          else
            nil
          end
        end

        def self.parse_gantt_date(date_string)
          if date_string.match('\d{4},\d{1,2},\d{1,2}')
            Date.strptime(date_string, '%Y,%m,%d')
          end
        end

        def css_classes
          css = 'version'
          css << " #{self.status}"
          css << " #{self.css_shared}" if self.css_shared

          return css
        end

        def reschedule_after(date)
          return if date.nil? || self.mass_operations_in_progress
          if effective_date.nil? || effective_date < date
            self.effective_date = date
            save
            reschedule_following_issues(date)
          elsif effective_date > date
            self.effective_date = date
            reschedule_following_issues(date)
            save
          end
        end

        def reschedule_following_issues(date)
          return if self.mass_operations_in_progress
          self.fixed_issues.joins(:status).distinct.where(["#{IssueStatus.table_name}.is_closed = ? AND #{Issue.table_name}.due_date IS NOT NULL", false]).each do |issue|
            journal        = issue.init_journal(User.current)
            issue.due_date = date
            issue.save
          end
        end

        def validate_effective_date
          if self.project && !self.effective_date.nil? && !EasySetting.value('project_calculate_due_date') && !self.project.easy_due_date.nil? && self.effective_date > self.project.easy_due_date
            errors.add :effective_date, :before_project_end, :due_date => format_date(self.effective_date), :project_due_date => format_date(self.project.easy_due_date)
          end
        end

        def sum_of_issues_estimated_hours_scope(only_self = false)
          Issue.where("#{Issue.table_name}.fixed_version_id = ?", self.id).where("#{Issue.table_name}.estimated_hours IS NOT NULL")
        end

      end
    end

    module InstanceMethods
      def deletable_with_easy_extensions?
        return false unless deletable_without_easy_extensions?

        User.current.allowed_to?(:manage_versions, self.project)
      end
    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Version', 'EasyPatch::VersionPatch'
