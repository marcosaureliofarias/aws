module EasyPatch
  module TimeEntryPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do
        remove_validation :comments, 'validates_length_of'
        validates_length_of :comments, :maximum => 65535, :allow_nil => true

        html_fragment :comments, scrub: :strip, force: true

        if EasyAttendance.table_exists?
          attr_accessor :skip_destroy_easy_attendance
          has_one :easy_attendance, autosave: false
          after_destroy :destroy_easy_attendance, :if => lambda { !@skip_destroy_easy_attendance }
        end

        belongs_to :entity, :polymorphic => true
        belongs_to :easy_locked_by, :class_name => 'User'
        belongs_to :easy_unlocked_by, :class_name => 'User'

        scope :visible_with_archived, lambda { |*args| visible(args.shift || User.current, :include_archived => true) }
        # scope :visible_with_archived, lambda {|*args| visible(args)}
        scope :non_templates, lambda { joins(:project).where(["#{Project.table_name}.easy_is_easy_template = ?", false]) }

        before_validation :set_entity_columns_if_missing

        validates :issue_id, presence: true, if: :issue_must_be_selected?
        validate :only_open_issue, if: proc { |t| t.issue && t.issue.closed? && !t.issue.closing? && !EasyGlobalTimeEntrySetting.value('allow_log_time_to_closed_issue', User.current.roles_for_project(t.project)) }
        validate :validate_time_entry_for_workers, if: proc { |t| t.should_validate_time_entry_for_workers? }
        validate :validate_easy_lock, if: proc { |t| t.class.easy_locking_enabled? && !t.easy_locked_changed? }
        validates :comments, presence: true, if: :comment_must_be_filled?
        validate :validate_spent_on_range

        attr_accessor :mass_operations_in_progress
        attr_accessor :skip_issue_id_validation

        safe_attributes 'easy_range_to', 'easy_range_from', 'hours_hour', 'hours_minute', 'entity_id', 'entity_type'
        safe_attributes 'easy_locked', :if => Proc.new { |t| t.class.easy_locking_enabled? && (t.can_lock? || t.can_unlock?) }
        safe_attributes 'user_id', :if => Proc.new { |t| User.current.allowed_to_globally?(:add_timeentries_for_other_users) }

        before_save :cancel_save_if_project_is_template
        before_save :resolve_easy_lock, :if => Proc.new { |t| t.class.easy_locking_enabled? && t.easy_locked_changed? }
        before_save :set_easy_divided_hours

        before_destroy :validate_before_destroy

        delegate :created_on, :updated_on, :closed_on, :open_duration_in_hours, :assigned_to, :easy_external_id, to: :issue, prefix: true, allow_nil: true
        delegate :tracker, :fixed_version, :category, to: :issue, allow_nil: true

        alias_method_chain :safe_attributes=, :easy_extensions
        alias_method_chain :editable_by?, :easy_extensions
        alias_method_chain :validate_time_entry, :easy_extensions

        class << self

          cattr_accessor :available_entity_types

          def available_entity_types
            @@available_entity_types ||= ['Issue', 'Project']
          end

        end

        def self.easy_locking_enabled?
          EasySetting.value('time_entries_locking_enabled')
        end

        def estimated_hours
          self.issue.try(:estimated_hours)
        end

        def user_roles
          self.user&.roles_for_project(self.project)
        end

        def project_root
          self.project.root
        end

        def parent_project
          @parent_project ||= self.project.parent_project if self.project
        end

        def css_classes
          css = 'time_entry'
          css << '_' + self.issue.css_classes(User.current, nil, { inline_editable: false }) if self.issue
          css << ' time-entry-easy-is-easy-locked' if self.easy_locked?

          return css
        end

        def should_validate_time_entry_for_workers?
          !(modifing_only_lock? || User.current.admin?)
        end

        def modifing_only_lock?
          (changed - %w[easy_locked easy_locked_by_id easy_locked_at easy_unlocked_by_id easy_unlocked_at]).empty?
        end

        def visible_custom_field_values
          return [] if self.project && self.activity && self.activity.is_default? && !self.project.activities.include?(self.activity)
          custom_field_values.select do |value|
            value.custom_field.visible_by_activity?(self.activity) && value.custom_field.visible_by?(self.project, User.current)
          end
        end

        def can_lock?(user = nil)
          user ||= User.current
          user.allowed_to_globally?(:timelog_can_easy_locking, {})
        end

        def can_unlock?(user = nil)
          user ||= User.current
          user.allowed_to_globally?(:timelog_can_easy_unlocking, {})
        end

        def easy_user_hours_ratio
          TimeEntry.easy_user_hours_ratio(user_id)
        end

        def self.easy_user_hours_ratio(user_id)
          1.0
        end

        private

        def cancel_save_if_project_is_template
          throw(:abort) if self.project.easy_is_easy_template?
        end

        def only_open_issue
          errors.add(:issue_id, I18n.t(:text_validation_error_only_open_issue))
        end

        def set_entity_columns_if_missing
          return true if !self.class.column_names.include?('entity_id')
          return true if !self.entity_id.blank? && !self.entity_type.blank?

          if !self.issue_id.blank?
            self.entity_id   = self.issue_id
            self.entity_type = 'Issue'
          else
            self.entity_id   = self.project_id
            self.entity_type = 'Project'
          end

          return true
        end

        def validate_time_entry_for_workers
          return if !self.spent_on || !self.user
          roles                   = user_roles
          before_today_limit      = EasyGlobalTimeEntrySetting.value('spent_on_limit_before_today', roles).presence
          before_today_edit_limit = EasyGlobalTimeEntrySetting.value('spent_on_limit_before_today_edit', roles).presence
          after_today_limit       = EasyGlobalTimeEntrySetting.value('spent_on_limit_after_today', roles).presence
          after_today_edit_limit  = EasyGlobalTimeEntrySetting.value('spent_on_limit_after_today_edit', roles).presence
          time_entry_daily_limit  = EasyGlobalTimeEntrySetting.value('time_entry_daily_limit', roles).presence

          before_limit_day         = get_limit_day(before_today_limit && (before_today_limit.to_i * -1), before_today_edit_limit && (before_today_edit_limit.to_i * -1))
          after_limit_day          = get_limit_day(after_today_limit, after_today_edit_limit)
          total_spent_time_on_date = self.user.sum_spent_time_for(self.spent_on)
          self_difference          = (self.new_record? || spent_on_changed?) ? self.hours.to_f : (self.hours.to_f - self.hours_was.to_f)

          validate_range(self.spent_on, before_limit_day, after_limit_day)
          validate_range(self.spent_on_was, before_limit_day, after_limit_day) if spent_on_changed? && self.spent_on_was
          if time_entry_daily_limit && time_entry_daily_limit < (total_spent_time_on_date + self_difference)
            errors.add(:base, :limit_exceeded, { :limit => time_entry_daily_limit, :total => total_spent_time_on_date })
          end
        end

        def validate_range(date, before_limit_day, after_limit_day)
          errors.add(:spent_on, :out_of_range) if before_limit_day && date < before_limit_day
          errors.add(:spent_on, :out_of_range) if after_limit_day && date > after_limit_day
        end

        def get_limit_day(create_today_limit, edit_today_limit)
          user = self.user || User.current
          if self.new_record? && !create_today_limit.nil?
            # add
            if create_today_limit == 0
              limit_day = user.today
            else
              limit_day = user.current_working_time_calendar.shift_working_day(create_today_limit.to_i, user.today)
            end
          elsif !self.new_record? && !edit_today_limit.nil?
            # edit
            # base_time = self.created_on.to_date
            # limit_day = base_time + edit_today_limit.to_i
            if edit_today_limit == 0
              limit_day = user.today
            else
              limit_day = user.current_working_time_calendar.shift_working_day(edit_today_limit.to_i, user.today)
            end
          else
            limit_day = nil
          end

          limit_day
        end

        def validate_easy_lock
          errors.add(:base, :is_locked) if self.easy_locked?
        end

        def resolve_easy_lock
          if self.easy_locked_was
            self.easy_unlocked_by = User.current
            self.easy_unlocked_at = Time.now.localtime
          else
            self.easy_locked_by = User.current
            self.easy_locked_at = Time.now.localtime
          end
        end

        def validate_spent_on_range
          errors.add(:spent_on, :out_of_range) if spent_on && !spent_on.year.in?(2000..2200)
        end

        def destroy_easy_attendance
          self.easy_attendance && self.easy_attendance.destroy if !@skip_destroy_easy_attendance
        end

        def set_easy_divided_hours
          return true if !self.class.column_names.include?('easy_divided_hours')

          self.easy_divided_hours = hours.to_f / easy_user_hours_ratio.to_f

          return true
        end

        def issue_must_be_selected?
          ['Issue', 'Project'].include?(entity_type) && !skip_issue_id_validation && easy_attendance.nil? && EasyGlobalTimeEntrySetting.value('required_issue_id_at_time_entry', user_roles)
        end

        def comment_must_be_filled?
          easy_attendance.nil? && EasyGlobalTimeEntrySetting.value('required_time_entry_comments', user_roles)
        end
      end
    end

    module InstanceMethods

      def safe_attributes_with_easy_extensions=(values, *args)
        values = values.to_unsafe_hash if values.respond_to?(:to_unsafe_hash)

        if values && values.is_a?(Hash)
          if (time = values.delete('easy_time_entry_range'))
            easy_range_from = time_for_time_entry_range(time['from'])
            easy_range_to   = time_for_time_entry_range(time['to'])

            if easy_range_from && easy_range_to
              values['easy_range_from'] = easy_range_from
              values['easy_range_to']   = easy_range_to
              values['hours']           = hours_from_range(easy_range_from, easy_range_to)
            elsif time['from'] && time['to']
              values['easy_range_from'] = nil
              values['easy_range_to']   = nil
            end
          end

          if values['hours_hour'] && values['hours_minute']
            h = values.delete('hours_hour').to_i
            m = values.delete('hours_minute').to_i

            values['hours'] = h + (m / 60.0)
          end

          #values['hours'] = '' if values['hours'] && (values['hours'].to_s == '0' || values['hours'].to_s == '0.0')
        end

        send :safe_attributes_without_easy_extensions=, values, *args

        self.activity = self.issue.activity if self.project && self.issue && self.project.fixed_activity? && self.issue.activity
      end

      def editable_by_with_easy_extensions?(usr)
        editable_by_without_easy_extensions?(usr) || User.current.allowed_to?(:add_timeentries_for_other_users_on_project, project) || User.current.allowed_to_globally?(:add_timeentries_for_other_users)
      end

      def allow_time_entry_zero_hours?
        activity && activity.allow_time_entry_zero_hours?
      end

      def allow_time_entry_negative_hours?
        activity && activity.allow_time_entry_negative_hours?
      end

      def validate_time_entry_with_easy_extensions
        if hours
          errors.add :hours, :invalid if hours >= 1000
          errors.add :hours, :invalid if hours == 0 && !allow_time_entry_zero_hours?
          errors.add :hours, :invalid if hours < 0 && !allow_time_entry_negative_hours?
        end

        if project.nil?
          errors.add :project_id, :invalid

        elsif project.archived?
          errors.add :project_id, :can_not_log_time_on_archived_project

        elsif project.easy_is_easy_template?
          errors.add :project_id, :can_not_log_time_on_template_project

        elsif (issue_id && !issue) || (issue && project != issue.project) || @invalid_issue_id
          errors.add :issue_id, :invalid
        end

        if activity_id_changed? && project && (!project.activities_per_role(user, 'xAll').include?(activity) &&
            !(project.activities.include?(activity) &&
                (
                User.current.allowed_to?(:add_timeentries_for_other_users_on_project, project) ||
                    User.current.allowed_to_globally?(:add_timeentries_for_other_users, {})
                )
            ))
          errors.add :activity_id, :inclusion
        end
      end

      def valid_for_destroy?
        validate_before_destroy
      rescue
        false
      end

      private

      def validate_before_destroy
        (!User.current.admin? && !validate_time_entry_for_workers) || (self.class.easy_locking_enabled? && !validate_easy_lock)
        if errors.any?
          throw(:abort)
        else
          true
        end
      end

      def time_for_time_entry_range(value)
        if value.present? && (m = value.match(/^([0-1]?[0-9]|2[0-3])([:\-,\.])?([0-5][0-9])$/))
          date = Date.today
          User.current.user_civil_time_in_zone(date.year, date.month, date.day, m[1], m[3])
        end
      end

      def hours_from_range(from, to)
        to.strftime('%H:%M').to_hours - from.strftime('%H:%M').to_hours
      end

    end

    module ClassMethods

      def sum_previous_month_hours(project)
        current_month_start = Date.today.at_beginning_of_month
        previous_month      = (current_month_start - 1.month)..(current_month_start - 1.day)

        self.sum_spent_hours(project, previous_month)
      end

      def sum_previous_week_hours(project)
        current_week_start = Date.today - (Date.today.cwday - EasyExtensions::Calendars::Calendar.first_wday) % 7
        previous_week = (current_week_start - 1.week)..(current_week_start - 1.day)

        self.sum_spent_hours(project, previous_week)
      end

      def sum_total_spent_hours(project)
        self.sum_spent_hours(project)
      end

      def sum_spent_hours(project, period = nil)
        if project
          scope = TimeEntry.joins(:project).where(:projects => { :lft => project.lft..project.rgt, :rgt => project.lft..project.rgt })
        else
          scope = TimeEntry
        end
        scope = scope.where(:spent_on => period) if period.present?
        scope.sum(:hours)
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'TimeEntry', 'EasyPatch::TimeEntryPatch'
