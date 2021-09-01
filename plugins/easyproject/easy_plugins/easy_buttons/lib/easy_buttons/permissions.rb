Redmine::AccessControl.map do |map|
  map.project_module :easy_other_permissions do |pmap|
    pmap.permission(:manage_easy_buttons,
      {
        easy_buttons: [:index, :new, :copy, :create, :edit, :update, :update_form, :destroy, :context_menu]
      },
      require: :loggedin,
      global: true
    )
    pmap.permission(:manage_own_easy_buttons,
      {
        easy_buttons: [:index, :new, :copy, :create, :edit, :update, :update_form, :destroy, :context_menu],
      },
      require: :loggedin,
      global: true
    )
    pmap.permission(:execute_easy_buttons,
      {
        easy_buttons: [:execute]
      },
      require: :loggedin,
      global: true
    )
  end
end
