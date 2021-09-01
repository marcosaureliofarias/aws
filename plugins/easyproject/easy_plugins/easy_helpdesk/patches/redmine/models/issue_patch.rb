module EasyHelpdesk
  module IssuePatch

    def self.included(base)
      base.include(InstanceMethods)
      base.include(Rails.application.routes.url_helpers)

      base.class_eval do

        has_many :easy_sla_events, dependent: :destroy
        belongs_to :easy_helpdesk_project_sla
        belongs_to :easy_helpdesk_ticket_owner, class_name: 'Principal'
        before_create :set_easy_helpdesk_properties
        before_update :ensure_correct_sla_data, if: proc { |i| i.maintained_by_easy_helpdesk? && ( i.priority_id_changed? || i.tracker_id_changed? || i.status_id_changed?) }
        before_save :update_easy_reopen_at
        after_create_commit :send_easy_helpdesk_mail

        attr_accessor :easy_helpdesk_mail_template

        safe_attributes 'easy_response_date_time'
        safe_attributes 'easy_helpdesk_need_reaction', :if => lambda {|issue, user| issue.attributes_editable?(user) }
        safe_attributes 'easy_helpdesk_ticket_owner_id', if: -> (issue, user) { issue.maintained_by_easy_helpdesk? && issue.attributes_editable?(user) }
        safe_attributes 'easy_helpdesk_mail_template'
        safe_attributes 'easy_helpdesk_mailbox_username'

        remove_validation :easy_email_to, 'presence'
        validates :easy_email_to, presence: true, if: -> { maintained_by_easy_helpdesk? && (easy_helpdesk_mail_template.present? || send_to_external_mails == '1') }, on: :update

        journalized_options[:non_journalized_columns].concat(['easy_helpdesk_project_sla_id', 'easy_time_to_solve_paused_at', 'easy_response_date_time', 'easy_time_to_solve_pause'])
        journalized_options[:format_detail_boolean_columns] << 'easy_helpdesk_need_reaction'
        journalized_options[:format_detail_reflection_columns] << 'easy_helpdesk_ticket_owner_id'

        def self.default_url_options
          Mailer.default_url_options
        end

        def self.display_easy_helpdesk_info?
          User.current.internal_client?
        end

        def display_easy_helpdesk_info?
          self.class.display_easy_helpdesk_info? && easy_helpdesk_project_sla
        end

        def maintained_by_easy_helpdesk?
          @maintained_by_easy_helpdesk ||= !maintained_easy_helpdesk_project.nil?
        end

        def maintained_easy_helpdesk_project
          return @maintained_easy_helpdesk_project if @maintained_easy_helpdesk_project

          if self.project_id# && self.tracker_id
            @maintained_easy_helpdesk_project = self.project.easy_helpdesk_project
            # @maintained_easy_helpdesk_project = EasyHelpdeskProject.where(:project_id => self.project_id).first#.where(:tracker_id => self.tracker_id).first
          end

          @maintained_easy_helpdesk_project
        end

        def easy_helpdesk_replace_tokens(text, journal=nil, mail_template=nil)
          t = text.to_s.dup
          tokens = {
              task_id: "##{id}",
              task_id_without_hash: id,
              task_subject: subject,
              spent_time: time_entries.sum(:hours).to_f.round(2).to_s
          }
          tokens[:time_spent] = tokens[:spent_time]
          if self.assigned_to
            tokens[:assignee] = assigned_to.name
          else
            tokens[:assignee] =  l(:label_nobody)
          end
          if /%\s?task_note\s?%/.match?(t)
            if journal.nil?
              task_note = self.journals.last.notes if self.journals.any?
            else
              task_note = journal.notes
            end
          end
          tokens[:task_note] = task_note.to_s
          self.custom_field_values.each do |cf_value|
            tokens[:"task_cf_#{cf_value.custom_field.id}"] = cf_value.value.to_s
          end
          tokens[:user_signature] = User.current.easy_mail_signature.to_s

          tokens[:author] = self.author
          tokens[:mail_to] = self.easy_email_to
          tokens[:date] = format_date(Time.now).to_s
          tokens[:task_tracker] = self.tracker.try(:name).to_s
          tokens[:task_project] = self.project.name.to_s
          tokens[:task_description] = self.description.to_s
          tokens[:task_status] = self.status.try(:name).to_s
          tokens[:task_priority] = self.priority.try(:name).to_s
          tokens[:task_estimated_hours] = self.estimated_hours.to_f.round(2).to_s
          tokens[:task_done_ratio] = self.done_ratio.to_s
          tokens[:task_public_url] = issue_url(self)
          tokens[:task_closed_on] = format_date(self.closed_on).to_s
          tokens[:task_due_date] = format_date(self.due_date).to_s
          tokens[:task_start_date] = format_date(self.start_date).to_s
          tokens[:user_id] = User.current.id.to_s
          tokens[:user_login] = User.current.login.to_s
          tokens[:user_name] = User.current.name.to_s
          tokens[:user_first_name] = User.current.firstname.to_s
          tokens[:user_last_name] = User.current.lastname.to_s

          # map = []; values = {}
          # tokens.each do |token, value|
          #   map << /%\s?#{token}\s?%/
          #   values.store "%#{token}%", value
          # end
          # t.gsub!(Regexp.union(map), values)

          tokens.each do |token, value|
            t.gsub!(/%\s?#{token}\s?%/, value.to_s)
          end

          # t = t % tokens

          t = replace_last_non_private_comment(t, journal)
          t = replace_history_token(t)

          t
        end

        def update_easy_reopen_at
          if reopening? && maintained_by_easy_helpdesk? && EasySetting.value('easy_helpdesk_reopen_resets_start_time_for_sla', self.project) == '1'
            self.easy_reopen_at = updated_on
            ensure_correct_sla_data
          end
        end

        def easy_helpdesk_project_sla_date_time(hours, pause = nil)
          time_value = (self.easy_reopen_at || self.created_on || Time.now).localtime
          time_value += hours.to_f.hours
          time_value += pause if pause
          time_value
        end

        def easy_helpdesk_project_sla_date_time_with_working_time(sla, hours, pause = nil)
          base = (self.easy_reopen_at || self.created_on || Time.now).localtime
          base_date = base.to_date
          limit = 365.days
          hours_from = sla.hours_mode_from_value.to_f
          hours_to = sla.hours_mode_to_value.to_f
          calendar = sla.easy_user_working_time_calendar
          remaining_hours = hours.to_f
          remaining_hours = ((remaining_hours * 1.hour) + pause.to_f) / 1.hour if pause
          time_value = base

          base_date.upto(base_date + limit) do |day|
            time_value_hours = time_value.hour.hours + time_value.min.minutes + time_value.sec.seconds
            if base_date == day
              if time_value_hours < hours_from.hours
                time_value = Time.new(day.year, day.month, day.day) + hours_from.hours
              elsif time_value_hours > hours_to.hours
                time_value = Time.new(day.year, day.month, day.day) + hours_from.hours
                next
              end
            else
              time_value = Time.new(day.year, day.month, day.day) + hours_from.hours
            end
            next if calendar && calendar.easy_helpdesk_sla_non_working_day?(day)

            daily_allocation = hours_to - ((time_value.hour.hours + time_value.min.minutes + time_value.sec.seconds) / 1.hour.to_f)
            if remaining_hours < daily_allocation
              time_value += remaining_hours.hours
              #remaining_hours = 0
              break
            else
              remaining_hours -= daily_allocation
            end
          end
          time_value
        end

        def easy_helpdesk_project_sla_time_to_response
          if (time_value = self.easy_response_date_time)
            (time_value - Time.now) / 1.hour
          else
            0
          end
        end

        def easy_helpdesk_project_sla_time_to_solve
          if (time_value = self.easy_due_date_time)
            (time_value - Time.now) / 1.hour
          else
            0
          end
        end

        def easy_time_to_solve_pause_diff(sla)
          if self.easy_time_to_solve_paused?
            resumed_at = Time.now.localtime
            paused_at = easy_time_to_solve_paused_at.localtime
            if sla.use_working_time
              calendar = sla.easy_user_working_time_calendar
              working_hours_from = sla.hours_mode_from.to_f
              working_hours_to = sla.hours_mode_to.to_f
              working_time_between_two_times(working_hours_from, working_hours_to, paused_at, resumed_at, calendar)
            else
              (resumed_at - paused_at).seconds.to_f
            end
          else
            0.0
          end
        end

        def working_time_between_two_times(working_hours_from, working_hours_to, start_time, end_time, calendar=nil)
          start_time = [start_time, start_time.beginning_of_day + working_hours_from.hours].max
          start_time = [start_time, start_time.beginning_of_day + working_hours_to.hours].min
          end_time = [end_time, end_time.beginning_of_day + working_hours_from.hours].max
          end_time = [end_time, end_time.beginning_of_day + working_hours_to.hours].min
          if (start_time.to_date == end_time.to_date) && (!calendar || calendar.working_day?(start_time.to_date))
            return end_time - start_time
          end

          result = 0
          work_day_hours = working_hours_to - working_hours_from

          start_time.to_date.upto(end_time.to_date) do |day|
            if !calendar || (calendar && calendar.working_day?(day))
              if day == start_time.to_date
                result += working_hours_to.hours - start_time.seconds_since_midnight
              elsif day == end_time.to_date
                result += end_time.seconds_since_midnight - working_hours_from.hours
              else
                result += work_day_hours.hours
              end
            end
          end
          result
        end

        def easy_sla_data_recalculate(sla)
          self.easy_helpdesk_project_sla_id = sla.id
          pause = self.easy_sla_pause(sla)

          if sla.hours_to_solve.present?
            if sla.use_working_time
              self.easy_due_date_time = easy_helpdesk_project_sla_date_time_with_working_time(sla, sla.hours_to_solve, pause)
            else
              self.easy_due_date_time = easy_helpdesk_project_sla_date_time(sla.hours_to_solve, pause)
            end
            if self.easy_due_date_time
              new_due_date = self.easy_due_date_time.localtime.to_date
              self.due_date = self.start_date ? [self.start_date, new_due_date].max : new_due_date
            end
          else
            self.easy_due_date_time = nil
          end

          if sla.hours_to_response.present?
            if sla.use_working_time
              self.easy_response_date_time = easy_helpdesk_project_sla_date_time_with_working_time(sla, sla.hours_to_response, pause)
            else
              self.easy_response_date_time = easy_helpdesk_project_sla_date_time(sla.hours_to_response, pause)
            end
          else
            self.easy_response_date_time = nil
          end
        end

        def easy_sla_pause(sla)
          self.easy_time_to_solve_pause = nil if self.easy_helpdesk_project_sla_id_changed?

          if (stop_statuses = EasySetting.value('easy_helpdesk_sla_stop_states')) && stop_statuses.include?(self.status_id.to_s)
            set_easy_time_to_solve_pause
          elsif (start_statuses = EasySetting.value('easy_helpdesk_sla_start_states')) && start_statuses.include?(self.status_id.to_s)
            diff = easy_time_to_solve_pause_diff(sla)
            self.easy_time_to_solve_pause = self.easy_time_to_solve_pause.to_f + diff

            self.easy_time_to_solve_paused_at = nil
          end

          self.easy_time_to_solve_pause.ceil if self.easy_time_to_solve_pause
        end

        def set_easy_time_to_solve_pause
          self.easy_time_to_solve_paused_at = DateTime.now unless self.easy_time_to_solve_paused?
        end

        def easy_time_to_solve_paused?
          !self.easy_time_to_solve_paused_at.nil?
        end

        def ensure_correct_sla_data(from_mailbox = false)
          if sla = self.easy_helpdesk_project_sla_from_project(from_mailbox)
            self.easy_sla_data_recalculate(sla)
          end
        end

        def easy_helpdesk_project_sla_from_project(from_mailbox = true)
          return unless self.project && ehp = self.project.easy_helpdesk_project

          ehp.easy_helpdesk_project_sla.order(:position).to_a.detect do |sla|
            result = false

            if from_mailbox && self.easy_helpdesk_mailbox_username.present? && (kw = sla.keyword.to_s.strip).present?
              result = EasyHelpdeskProject.detect_keyword(kw, self.subject)
            end

            if !result && sla.priority_id && (sla.priority_id == self.priority_id) && (sla.tracker_id == self.tracker_id)
              result = true
            end

            result
          end
        end

        def set_easy_helpdesk_properties
          return unless self.project && ehp = self.project.easy_helpdesk_project

          if sla = self.easy_helpdesk_project_sla_from_project
            if self.easy_helpdesk_mailbox_username.present?
              self.priority_id = (sla.priority_id.nil? ? IssuePriority.default.try(:id) : sla.priority_id)
              if sla.tracker_id
                self.tracker = self.project.trackers.where(:id => sla.tracker_id || ehp.tracker_id).first || self.project.trackers.first
              end
            end
            self.easy_sla_data_recalculate(sla)
          end

          self.status ||= self.tracker.default_status if self.tracker

          self.watcher_group_ids = self.watcher_group_ids | Group.active.where(:id => Array.wrap(ehp.watcher_groups_ids)).pluck(:id)
          user_from_group_ids = Group.where(id: self.watcher_group_ids).map{|g| g.user_ids}.flatten
          self.watcher_user_ids = (self.watcher_user_ids | User.active.where(:id => Array.wrap(ehp.watchers_ids)).pluck(:id)) - user_from_group_ids
        end

        def easy_helpdesk_project_monthly_hours
          self.project.easy_helpdesk_project_monthly_hours
        end

        def easy_due_date_time_remaining
          self.easy_helpdesk_project_sla_time_to_solve
        end

        def easy_response_date_time_remaining
          self.easy_helpdesk_project_sla_time_to_response
        end

        def easy_helpdesk_sla_visible_for?(user)
          user ||= User.current
          user.allowed_to?(:view_easy_helpdesk_sla, self.project)
        end

        def send_easy_helpdesk_mail
          return if self.easy_email_to.blank? || self.easy_helpdesk_mailbox_username.blank?

          mail_template = EasyHelpdeskMailTemplate.find_from_issue(self)

          return if mail_template.nil?

          mail_template.send_to = self.easy_email_to
          mail_template.send_cc = self.easy_email_cc if self.easy_email_cc.present?

          EasyHelpdeskMailer.received_support_ticket(self, mail_template).deliver
        end

      end
    end

    module InstanceMethods
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Issue', 'EasyHelpdesk::IssuePatch'
