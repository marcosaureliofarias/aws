Rys::Patcher.add('EasyQueryButtonsHelper') do

  apply_if_plugins :easy_extensions

  included do

    def easy_oauth2_application_query_additional_ending_buttons(entity, options = {})
      s = ''

      s << link_to(l(:button_edit),
                   edit_easy_oauth2_application_path(entity),
                   class: 'icon icon-edit',
                   title: l(:button_edit)) if entity.editable?
      s << link_to(l(:button_authorize, scope: :easy_oauth2),
                   authorization_easy_oauth2_application_path(entity),
                   class: 'icon icon-key',
                   title: l(:button_authorize, scope: :easy_oauth2)) if entity.is_a?(EasyOauth2ClientApplication) && entity.editable?
      s << link_to(l(:button_delete),
                   easy_oauth2_application_path(entity),
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
