if Redmine::Plugin.installed?(:easy_extensions)
  Redmine::AccessControl.map do |map|

    map.easy_category :easy_actions do |pmap|
      pmap.rys_feature('easy_actions') do |fmap|

        fmap.permission(:view_easy_actions, {
            easy_action_check_templates:     %i[index show autocomplete],
            easy_action_checks:              %i[index show],
            easy_action_sequence_categories: %i[index show],
            easy_action_sequence_instances:  %i[index show chart],
            easy_action_sequences:           %i[index show autocomplete modal_index],
            easy_action_states:              %i[index show autocomplete],
            easy_action_transitions:         %i[index show autocomplete],
        }, global: true, read: true)

        fmap.permission(:manage_easy_actions, {
            easy_action_check_templates:     %i[new create edit update destroy],
            easy_action_checks:              %i[new create edit update destroy passed failed],
            easy_action_sequence_categories: %i[new create edit update destroy],
            easy_action_sequence_instances:  %i[new create edit update destroy check_state],
            easy_action_sequences:           %i[new create edit update destroy],
            easy_action_states:              %i[new create edit update destroy],
            easy_action_transitions:         %i[new create edit update destroy],
        }, global: true)
      end
    end

  end
end