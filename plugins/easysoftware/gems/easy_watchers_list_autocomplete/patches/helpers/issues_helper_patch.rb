Rys::Patcher.add('IssuesHelper') do

  included do

    def easy_watchers_list_autocomplete_select_users_and_groups(users, groups, selected_user_ids, select_group_ids)
      select_users_and_groups = []
      select_users_and_groups.concat(easy_watchers_list_autocomplete_select_principals(users, selected_user_ids)) if selected_user_ids && users
      select_users_and_groups.concat(easy_watchers_list_autocomplete_select_principals(groups, select_group_ids)) if select_group_ids && groups
      select_users_and_groups
    end

    def easy_watchers_list_autocomplete_select_principals(principals, selected_principal_ids)
      selected = principals.select { |principal| selected_principal_ids.include?(principal.id.to_s) }
      selected
    end

  end

end
