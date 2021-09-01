class MigrateKnowledgePermissions  < EasyExtensions::EasyDataMigration

  def up
    Role.remove_validation :name
    Role.all.each do |role|
      old_permissions = role.permissions & [:view_easy_knowledge_stories,
                                            :create_global_stories,
                                            :read_global_stories,
                                            :manage_global_stories,
                                            :edit_own_global_stories,
                                            :edit_other_users_stories,
                                            :stories_assignment,
                                            :manage_user_stories,
                                            :manage_project_stories,
                                            :create_project_stories,
                                            :view_project_stories,
                                            :edit_project_stories,
                                            :edit_own_stories,
                                            :manage_project_categories]

      if old_permissions.any?
        role.remove_permission!(*old_permissions)

        role.add_permission!(:view_easy_knowledge)

        role.add_permission!(:read_global_stories) if old_permissions.include? :view_easy_knowledge_stories
        role.add_permission!(:create_global_stories, :read_global_stories) if old_permissions.include? :create_global_stories
        role.add_permission!(:read_global_stories) if old_permissions.include? :read_global_stories
        role.add_permission!(:manage_global_categories, :read_global_stories) if old_permissions.include? :manage_global_stories
        role.add_permission!(:edit_own_global_stories, :read_global_stories) if old_permissions.include? :edit_own_global_stories
        role.add_permission!(:edit_all_global_stories, :read_global_stories) if old_permissions.include? :edit_other_users_stories
        role.add_permission!(:stories_assignment) if old_permissions.include? :stories_assignment
        role.add_permission!(:manage_own_personal_categories, :read_global_stories) if old_permissions.include? :manage_user_stories

        role.add_permission!(:read_project_stories, :create_project_stories, :edit_all_project_stories) if old_permissions.include? :manage_project_stories
        role.add_permission!(:create_project_stories, :read_project_stories) if old_permissions.include? :create_project_stories
        role.add_permission!(:read_project_stories) if old_permissions.include? :view_project_stories
        role.add_permission!(:edit_all_project_stories, :read_project_stories) if old_permissions.include? :edit_project_stories
        role.add_permission!(:edit_own_project_stories, :read_project_stories) if old_permissions.include? :edit_own_stories
        role.add_permission!(:manage_project_categories) if old_permissions.include? :manage_project_categories
      end
    end
  end

  def down

  end
end
