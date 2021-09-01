Redmine::AccessControl.map do |map|
  map.project_module :easy_knowledge do |pmap|

    # can see KB in menus and can see && comment recommended posts
    pmap.permission :view_easy_knowledge, {
        easy_knowledge: [:index, :overview, :search, :show_toolbar, :sidebar_categories, :data, :show_as_tree],
        easy_knowledge_stories: [:index, :show, :toggle_favorite, :diff, :render_tabs, :mark_as_read, :add_comment],
        easy_knowledge_projects: [:stories_tree],
        easy_knowledge_categories: [:index],
        journals: [:diff]
    }, read: true, global: true

    # can see posts from global categories
    pmap.permission :read_global_stories, {
        easy_knowledge_globals: [:index, :show],
        journals: [:diff]
    }, read: true, global: true

    # can create global posts
    pmap.permission :create_global_stories, {
        easy_knowledge_stories: [:new, :create]
    }, global: true

    # can edit global posts I created
    pmap.permission :edit_own_global_stories, {
        easy_knowledge_stories: [:edit, :destroy, :update, :restore, :update_story_category],
        journals: [:edit]
    }, global: true

    # can edit all global posts
    pmap.permission :edit_all_global_stories, {
        easy_knowledge_stories: [:edit, :destroy, :update, :restore, :update_story_category],
        journals: [:edit]
    }, global: true

    # grants access to own personal categories
    pmap.permission :manage_own_personal_categories, {
        easy_knowledge_users: [:index, :create, :destroy, :edit, :new, :show, :update],
    }, global: true

    # can manage global categories
    pmap.permission :manage_global_categories, {
        easy_knowledge_globals: [:index, :show, :create, :destroy, :edit, :new, :update],
    }, global: true

    pmap.permission :manage_easy_knowledge_page, {
        easy_knowledge: [:layout]
    }, global: true

    # can recommend posts to other users
    pmap.permission :stories_assignment, {
        easy_knowledge_stories: [:remove_from_entity, :assign_entities]
    }, global: true


    # project permissions

    # can see project posts
    pmap.permission :read_project_stories, {
        easy_knowledge_projects: [:index, :show, :stories_tree],
        easy_knowledge_stories: [:index, :show, :mark_as_read, :diff, :render_tabs],
        journals: [:diff]
    }, read: true

    # can create project posts
    pmap.permission :create_project_stories, {
        easy_knowledge_stories: [:new, :create]
    }

    # can edit project posts I created
    pmap.permission :edit_own_project_stories, {
        easy_knowledge_stories: [:edit, :update, :destroy, :restore, :update_story_category],
        journals: [:edit]
    }

    # can edit all project posts
    pmap.permission :edit_all_project_stories, {
        easy_knowledge_stories: [:edit, :update, :destroy, :restore, :update_story_category],
        journals: [:edit]
    }

    # can manage project categories
    pmap.permission :manage_project_categories, {
        easy_knowledge_projects: [:index, :show, :create, :destroy, :edit, :new, :update],
    }

  end
end
