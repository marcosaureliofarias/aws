Redmine::MenuManager.map :admin_menu do |menu|
    menu.push :easy_helpdesk, { controller: 'easy_helpdesk', action: 'index' }, caption: :heading_easy_helpdesk_index, html: { class: 'icon icon-help-bubble' }, if: proc { User.current.admin? }, before: :settings
  end

  Redmine::MenuManager.map :admin_dashboard do |menu|
    menu.push :easy_helpdesk, { controller: 'easy_helpdesk', action: 'index' }, caption: :heading_easy_helpdesk_index, html: { menu_category: 'extensions', class: 'icon icon-help-bubble'}, if: proc { User.current.admin? }
  end

  Redmine::MenuManager.map :top_menu do |menu|
    menu_options = {
      caption: :easy_helpdesk_name,
      if: proc {User.current.allowed_to_globally?(:manage_easy_helpdesk, {})},
      html: {class: 'icon icon-help-bubble'}
    }
    if Redmine::Plugin.installed?(:easy_contacts)
      menu_options[:after] = :easy_contacts
    elsif Redmine::Plugin.installed?(:easy_crm)
      menu_options[:after] = :easy_crm
    else
      menu_options[:first] = true
    end

    menu.push(:easy_helpdesk, :easy_helpdesk_path, menu_options)
    menu.push(:easy_helpdesk_mailboxes, :easy_helpdesk_mailboxes_path, {
        parent: :easy_helpdesk,
        caption: :button_easy_helpdesk_mailboxes_index,
        if: proc {User.current.allowed_to_globally?(:manage_easy_helpdesk, {})}
      })
    menu.push(:easy_helpdesk_templates, :easy_helpdesk_mail_templates_path, {
        parent: :easy_helpdesk,
        caption: :button_easy_helpdesk_mail_templates_index,
        if: proc {User.current.allowed_to_globally?(:manage_easy_helpdesk, {})}
      })
  end