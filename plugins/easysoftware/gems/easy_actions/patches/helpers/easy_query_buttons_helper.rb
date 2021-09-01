Rys::Patcher.add('EasyQueryButtonsHelper') do

  apply_if_plugins :easy_extensions

  included do

    def easy_action_check_template_query_additional_ending_buttons(entity, options = {})
      s = ''

      s << link_to(l(:button_edit),
                   edit_easy_action_check_template_path(entity),
                   class: 'icon icon-edit',
                   title: l(:button_edit)) if entity.editable?
      s << link_to(l(:button_delete),
                   easy_action_check_template_path(entity),
                   method: :delete,
                   data:   { confirm: l(:text_are_you_sure) },
                   class:  'icon icon-del',
                   title:  l(:button_delete)) if entity.deletable?

      s.html_safe
    end

    def easy_action_sequence_template_query_additional_ending_buttons(entity, options = {})
      s = ''

      s << link_to(l(:button_choose_sequence_template, scope: :easy_actions),
                   easy_action_sequences_path(
                       easy_action_sequence:
                                 {
                                     easy_action_sequence_template_id: entity,
                                     entity_type:                      params[:entity_type],
                                     entity_id:                        params[:entity_id]
                                 },
                       back_url: params[:back_url]),
                   class:  'icon icon-play',
                   method: :post,
                   title:  l(:button_choose_sequence_template, scope: :easy_actions)) if params[:entity_type] && params[:entity_id]
      s << link_to(l(:button_edit),
                   edit_easy_action_sequence_template_path(entity),
                   class: 'icon icon-edit',
                   title: l(:button_edit)) if entity.editable?
      s << link_to(l(:button_delete),
                   easy_action_sequence_template_path(entity),
                   method: :delete,
                   data:   { confirm: l(:text_are_you_sure) },
                   class:  'icon icon-del',
                   title:  l(:button_delete)) if entity.deletable?

      s.html_safe
    end

    def easy_action_sequence_instance_query_additional_ending_buttons(entity, options = {})
      s = ''

      s << link_to(l(:button_show),
                   easy_action_sequence_instance_path(entity),
                   remote: true,
                   title:  l(:button_show),
                   class:  'button button-positive')

      s << link_to(l(:button_delete),
                   easy_action_sequence_path(entity),
                   method: :delete,
                   data:   { confirm: l(:text_are_you_sure) },
                   class:  'icon icon-del',
                   title:  l(:button_delete)) if entity.deletable?

      s.html_safe
    end

  end

  instance_methods do

  end

end
