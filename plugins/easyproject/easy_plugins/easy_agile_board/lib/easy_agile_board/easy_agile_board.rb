module EasyAgileBoard
  class << self

    def setting_for_issue_relation(relation_type, relation_position = nil, project_id = nil)
      setting = EasySetting.value('agile_board_statuses', project_id).symbolize_keys
      status_setting = setting[relation_type]
      # if statuses are more complex
      if status_setting && relation_position
        status_setting = Array(status_setting.detect{|k,v| k.to_i == relation_position }).last
      end

      status_setting
    end

    def issue_status_id(relation_type, relation_position = nil, project_id = nil)
      status_setting = setting_for_issue_relation(relation_type, relation_position, project_id)
      if status_setting.is_a?(Hash) && status_setting['status_id'].present?
        status_setting['status_id'].to_i
      else
        nil
      end
    end

    def issue_return_to(relation_type, relation_position = nil, project_id = nil)
      status_setting = setting_for_issue_relation(relation_type, relation_position, project_id)
      if status_setting.is_a?(Hash) && status_setting['return_to'].present?
        status_setting['return_to']
      else
        '__no_change__'
      end
    end

    # @param [Project] project
    # @param [Boolean] include_blank
    # @param [EasySprint] append_sprint
    # @return [Array] [ [name, project_name, ID], [...] ]
    def easy_sprints_for_select(project, include_blank: false, append_sprint: nil)
      scope = EasySprint.visible.of_project_with_global(project).sorted_by_project.sorted_by_date.to_a
      scope << append_sprint if append_sprint && !scope.include?(append_sprint)
      scope.map!{|s| [s.name, (s.project ? s.project.family_name(max_length: 100) : I18n.t(:label_others)), s.id] }
      scope.prepend ['', '', ''] if include_blank
      scope.group_by(&:second)
    end

    def easy_sprints_for_autocomplete(project)
      scope = EasySprint.visible.of_project_with_global(project).sorted_by_project.sorted_by_date.to_a
      scope.map!{|s| [s.to_s_with_project, s.id] }
      scope
    end

  end
end
