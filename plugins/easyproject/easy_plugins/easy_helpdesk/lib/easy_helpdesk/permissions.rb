Redmine::AccessControl.map do |map|
  map.easy_category :easy_helpdesk do |pmap|

    pmap.permission :manage_easy_helpdesk, {
      easy_helpdesk: [:index, :layout, :settings],
      easy_helpdesk_mail_templates: [:index, :show, :new, :create, :edit, :update, :destroy],
      easy_helpdesk_mailboxes: [:index, :test_mail],
      easy_helpdesk_projects: [:index, :show, :new, :create, :edit, :update, :destroy, :bulk_edit, :bulk_update, :copy_sla, :find_by_email]
    }, global: true

    pmap.permission :manage_easy_helpdesk_project, {
      easy_helpdesk_projects: [:index, :show, :new, :create, :edit, :update, :destroy, :bulk_edit, :bulk_update, :copy_sla]
    }

    pmap.permission :view_easy_helpdesk_sla, {}
  end
  map.easy_category(:easy_sla_events) do |pmap|
    pmap.permission :view_easy_sla_events, { easy_sla_events: [:index] }
    pmap.permission :manage_easy_sla_events, { easy_sla_events: [:destroy] }
  end
end
