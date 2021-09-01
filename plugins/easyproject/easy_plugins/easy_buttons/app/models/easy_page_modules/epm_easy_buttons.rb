class EpmEasyButtons < EasyPageModule

  def category_name
    @category_name ||= 'others'
  end

  def runtime_permissions(user)
    user.allowed_to_globally?(:execute_easy_buttons)
  end

  def get_show_data(settings, user, page_context={})
    buttons = EasyButton.visible_for_execution.silent.where(id: settings['button_ids'], entity_type: settings['button_type'])

    {
      buttons: buttons
    }
  end

  def get_edit_data(settings, user, page_context={})
    {
      available_buttons: EasyButton.visible_for_execution.silent
    }
  end

end
