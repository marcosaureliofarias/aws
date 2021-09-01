module EasyAgileBoard
  module EasyAgileExtensions

    def self.included(base)
      base.class_eval do
        before_save :update_issue_params, if: :phase_column_value_changed?

        scope :with_phase, ->(phase) { where(easy_agile_options[:phase_column] => phase) }

        def self.easy_agile_options(options = nil)
          @easy_agile_options ||= { easy_setting_name: 'agile_board_statuses', phase_column: 'relation_type', easy_sprint_method: :easy_sprint }
          @easy_agile_options.merge!(options) if options
          @easy_agile_options
        end

        def self.project_easy_setting(project_id)
          EasySetting.value(self.easy_agile_options[:easy_setting_name], project_id)
        end

      end
    end

    def project_easy_setting
      @project_easy_setting ||= self.class.project_easy_setting(project_id)
    end

    def agile_relation_type
      phase = __send__(self.class.easy_agile_options[:phase_column])
      phase > 0 ? self.class::TYPE_PROGRESS : self.class::TYPES.invert[phase]
    end

    def agile_relation_position
      phase = __send__(self.class.easy_agile_options[:phase_column])
      phase > 0 ? phase : nil
    end

    def agile_settings
      status_setting = project_easy_setting.to_h.symbolize_keys[agile_relation_type]
      # if statuses are more complex
      if status_setting && agile_relation_position
        status_setting = status_setting[agile_relation_position.to_s]
      end

      status_setting || {}
    end

    def issue_assign_to_status_id
      agile_settings['status_id'].presence
    end

    def issue_return_to_assignee
      agile_settings['return_to'] || '__no_change__'
    end

    def assigned_to_easy_sprint
      __send__(self.class.easy_agile_options[:easy_sprint_method]) if self.class.easy_agile_options[:easy_sprint_method]
    end

    def update_from_issue
      self.update(self.class.easy_agile_options[:phase_column] => phase_for_status_from_settings(issue.status_id))
    end

    #POSITIONED METHODS
    def set_default_position
      if position.nil?
        self.position = position_scope.maximum(:position).to_i + (new_record? || phase_column_value_changed? ? 1 : 0)
      end
    end

    def phase_column_value_changed?
      __send__("#{self.class.easy_agile_options[:phase_column]}_changed?")
    end

    def phase_for_status_from_settings(status_id)
      setting = project_easy_setting.stringify_keys

      progress_settings = setting['progress']
      if progress_settings.is_a?(Hash)
        progress_settings.each do |relation_position, relation_type_settings|
          if settings_include_status?(relation_type_settings, status_id)
            return relation_position.to_i
          end
        end
      end

      done_settings = setting['done']
      if done_settings.is_a?(Hash) && settings_include_status?(done_settings, status_id)
        return self.class::TYPES[self.class::TYPE_DONE]
      end

      self.class::TYPES[self.class::TYPE_BACKLOG]
    end

    private

    def settings_include_status?(settings, status_id)
      settings['state_statuses'].is_a?(Array) && settings['state_statuses'].include?(status_id.to_s)
    end

    def update_issue_params(options = nil)
      return if agile_relation_type == self.class::TYPE_BACKLOG
      options ||= {}

      issue.init_journal(User.current)

      safe_attrs = HashWithIndifferentAccess.new
      safe_attrs['status_id'] = issue_assign_to_status_id.to_i if issue_assign_to_status_id

      if assigned_to_easy_sprint
        safe_attrs['fixed_version_id'] = assigned_to_easy_sprint.version_id unless easy_sprint.version_id.blank?
        safe_attrs['easy_sprint_id'] = assigned_to_easy_sprint.id
      end

      case issue_return_to_assignee
      when '__nobody__'
        safe_attrs['assigned_to_id'] = ''
      when '__no_change__'
        # do nothing
      when '__author__'
        safe_attrs['assigned_to_id'] = issue.author_id
      when '__last_assigned_to__'
        last_user_assigned_to = issue.last_user_assigned_to
        safe_attrs['assigned_to_id'] = last_user_assigned_to.id if last_user_assigned_to
      when '__me__'
        safe_attrs['assigned_to_id'] = User.current.id
      else
        safe_attrs['assigned_to_id'] = issue_return_to_assignee.to_i
        safe_attrs.delete('assigned_to_id') if safe_attrs['assigned_to_id'] <= 0
      end

      safe_attrs['assigned_to_id'] = options[:assigned_to_id] if options[:assigned_to_id]

      issue.safe_attributes = safe_attrs

      Redmine::Hook.call_hook(:easy_agile_board_relation_status_change_before_issue_save, { hook_caller: self, issue: issue })

    end

  end
end
