module EasyKnowledgeStoriesHelper

  def render_easy_knowledge_story(story)
    render :partial => 'easy_knowledge_stories/story_user', :locals => { :story => story}
  end

  def breadcrumb_story(story = nil, project = nil)
    links = [link_to(l(:button_easy_knowledge), easy_knowledge_overview_path, :title => l(:title_easy_knowledge))]
    links << link_to(l(:label_easy_knowledge_stories), easy_knowledge_stories_path, :title => l(:label_easy_knowledge_stories))
    links << link_to(project.name, project_path(project), :title => project.name) if project
    links << link_to(story.name, easy_knowledge_story_path(story), :title => story.name) if story
    breadcrumb(links)
  end

  def breadcrumb_category(category, entity_type = nil)
    type = entity_type || category.entity_type
    categories = case type
    when 'User', 'Principal'
      cat = [link_to(l(:label_easy_knowledge_index_user), easy_knowledge_users_path, :title => l(:label_easy_knowledge_index_user))]
      cat.concat(category.self_and_ancestors.collect{|c| link_to(c.name, easy_knowledge_user_path(c), :title => l(:title_easy_knowledge))}) if category
      cat
    when 'Project'
      cat = [link_to(l(:label_easy_knowledge_index_project), project_easy_knowledge_projects_path(category.entity_id), :title => l(:label_easy_knowledge_index_project))]
      cat.concat(category.self_and_ancestors.collect{|c| link_to(c.name, project_easy_knowledge_project_path(category.entity_id, c), :title => l(:title_easy_knowledge))}) if category
      cat
    else
      cat = [link_to(l(:label_easy_knowledge_index_global), easy_knowledge_globals_path, :title => l(:label_easy_knowledge_index_global))]
      cat.concat(category.self_and_ancestors.collect{|c| link_to(c.name, easy_knowledge_global_path(c), :title => l(:title_easy_knowledge))}) if category
      cat
    end
    breadcrumb(([link_to(l(:button_easy_knowledge), easy_knowledge_overview_path, :title => l(:title_easy_knowledge))]) + categories)
  end

  #story
  def easy_knowledge_story_assign_to_global_link(back_url)
    easy_modal_selector_link_with_submit('EasyKnowledgeCategory', 'name', 'entity_ids', 'ids1', '$(\'#story-id\')', :url => { :back_url => back_url, :entity_action => 'easy_knowledge_global_categories', :query_name => :kb_assign_to_global }, :form_url => polymorphic_path([:assign_entities, @project, :easy_knowledge_stories], {:entity_type => 'EasyKnowledgeCategory'}), :trigger_options => {:name => l('button_easy_knowledge_stories_assign_to_global'), :html => {:title => l('title_easy_knowledge_stories_assign_to_global'), :class => 'button'}})
  end

  def easy_knowledge_story_assign_to_personal_link(back_url)
    easy_modal_selector_link_with_submit('EasyKnowledgeCategory', 'name', 'entity_ids', 'ids2', '$(\'#story-id\')', :url => { :back_url => back_url, :entity_action => 'easy_knowledge_personal_categories', :query_name => :kb_assign_to_personal }, :form_url => polymorphic_path([:assign_entities, @project, :easy_knowledge_stories], {:entity_type => 'EasyKnowledgeCategory'}), :trigger_options => {:name => l('button_easy_knowledge_stories_assign_to_personal'), :html => {:title => l('title_easy_knowledge_stories_assign_to_personal'), :class => 'button'}})
  end

  def easy_knowledge_story_assign_to_project_link(back_url)
    easy_modal_selector_link_with_submit('EasyKnowledgeProject', 'name', 'entity_ids', 'ids3', '$(\'#story-id\')', :form_url => polymorphic_path([:assign_entities, @project, :easy_knowledge_stories], {:entity_type => 'Project'}), :trigger_options => {:name => l('button_easy_knowledge_stories_assign_to_project'), :html => {:title => l('title_easy_knowledge_stories_assign_to_project'), :class => 'button'}})
  end

  def easy_knowledge_story_assign_to_project_category_link(back_url)
    easy_modal_selector_link_with_submit('EasyKnowledgeCategory', 'name', 'entity_ids', 'ids4', '$(\'#story-id\')', :url => { :back_url => back_url, :entity_action => 'easy_knowledge_project_categories', :query_name => :kb_assign_to_project, :project_id => @project }, :form_url => polymorphic_path([:assign_entities, @project, :easy_knowledge_stories], {:entity_type => 'EasyKnowledgeCategory'}), :trigger_options => {:name => l('button_easy_knowledge_stories_assign_to_project_category'), :html => {:title => l('title_easy_knowledge_stories_assign_to_project'), :class => 'button'}}) if @project
  end

  def easy_knowledge_story_assign_to_user_link(back_url)
    easy_modal_selector_link_with_submit('User', 'mail', 'entity_ids', 'ids5', '$(\'#story-id\')', url: {back_url: back_url, hook_id: 'easy_knowledge_story_assign_to_user_link'}, form_url: {controller: 'easy_knowledge_stories', action: 'assign_entities', entity_type: 'User', id: params[:id]}, form_options: {remote: true}, trigger_options: {name: l(:button_easy_knowledge_stories_send_recommend_mail), html: {title: l(:title_easy_knowledge_stories_send_recommend_mail), class: 'button'}})
  end

  def easy_knowledge_story_assign_to_group_link(back_url)
    easy_modal_selector_link_with_submit('Group', 'name', 'entity_ids', 'ids6', '$(\'#story-id\')', url: {back_url: back_url, hook_id: 'easy_knowledge_story_assign_to_group_link'}, form_url: {controller: 'easy_knowledge_stories', action: 'assign_entities', entity_type: 'Group', id: params[:id]}, form_options: {remote: true}, trigger_options: {name: l(:button_easy_knowledge_stories_send_recommend_mail_groups), html: {title: l(:title_easy_knowledge_stories_send_recommend_mail), :class => 'button icon icon-email-add'}})
  end

  def easy_knowledge_story_assign_to_issue_link(back_url)
    easy_modal_selector_link_with_submit('Issue', 'subject', 'entity_ids', 'ids7', '$(\'#story-id\')', :url => { :back_url => back_url, :entity_action => 'easy_knowledge_issue' }, :form_url => polymorphic_path([:assign_entities, @project, :easy_knowledge_stories], {:entity_type => 'Issue'}), :trigger_options => {:name => l('button_easy_knowledge_stories_assign_to_issue'), :html => {:title => l('title_easy_knowledge_stories_assign_to_issue'), :class => 'button icon icon-issue'}})
  end
  # /story

  #stories
  def list_checkboxes_selector
    "$('input:checkbox[name^=ids]')"
  end

  def easy_knowledge_stories_assign_to_global_link(back_url)
    easy_modal_selector_link_with_submit('EasyKnowledgeCategory', 'name', 'entity_ids', 'ids1', list_checkboxes_selector, :url => { :back_url => back_url, :entity_action => 'easy_knowledge_global_categories',:query_name => :kb_assign_to_global }, :form_url => polymorphic_path([:assign_entities, @project, :easy_knowledge_stories], {:entity_type => 'EasyKnowledgeCategory', :back_url => back_url}), :trigger_options => {:name => l('button_easy_knowledge_stories_assign_to_global'), :html => {:title => l('title_easy_knowledge_stories_assign_to_global'), :class => 'button'}})
  end

  def easy_knowledge_stories_assign_to_personal_link(back_url)
    easy_modal_selector_link_with_submit('EasyKnowledgeCategory', 'name', 'entity_ids', 'ids2', list_checkboxes_selector, :url => { :back_url => back_url, :entity_action => 'easy_knowledge_personal_categories', :query_name => :kb_assign_to_personal }, :form_url => polymorphic_path([:assign_entities, @project, :easy_knowledge_stories], {:entity_type => 'EasyKnowledgeCategory', :back_url => back_url}), :trigger_options => {:name => l('button_easy_knowledge_stories_assign_to_personal'), :html => {:title => l('title_easy_knowledge_stories_assign_to_personal'), :class => 'button'}})
  end

  def easy_knowledge_stories_assign_to_project_link(back_url)
    easy_modal_selector_link_with_submit('EasyKnowledgeCategory', 'name', 'entity_ids', 'ids3', list_checkboxes_selector, :url => { :back_url => back_url, :entity_action => 'easy_knowledge_project_categories', :query_name => :kb_assign_to_project }, :form_url => polymorphic_path([:assign_entities, @project, :easy_knowledge_stories], {:entity_type => 'EasyKnowledgeCategory', :back_url => back_url}), :trigger_options => {:name => l('button_easy_knowledge_stories_assign_to_project'), :html => {:title => l('title_easy_knowledge_stories_assign_to_project'), :class => 'button'}})
  end

  def easy_knowledge_stories_recommend_mail_link(back_url)
    easy_modal_selector_link_with_submit('User', 'mail', 'entity_ids', 'ids4', list_checkboxes_selector, :url => { :back_url => back_url }, :form_url => polymorphic_path([:assign_entities, @project, :easy_knowledge_stories], {:entity_type => 'User', :back_url => back_url}), :trigger_options => {:name => l('button_easy_knowledge_stories_send_recommend_mail'), :html => {:title => l('title_easy_knowledge_stories_send_recommend_mail'), :class => 'button icon icon-email-add'}})
  end

  def easy_knowledge_stories_assign_to_issue_link(back_url)
    easy_modal_selector_link_with_submit('Issue', 'subject', 'entity_ids', 'ids5', list_checkboxes_selector, :url => { :back_url => back_url, :entity_action => 'easy_knowledge_issue' }, :form_url => polymorphic_path([:assign_entities, @project, :easy_knowledge_stories], {:entity_type => 'Issue', :back_url => back_url}), :trigger_options => {:name => l('button_easy_knowledge_stories_assign_to_issue'), :html => {:title => l('title_easy_knowledge_stories_assign_to_issue'), :class => 'button icon icon-issue'}})
  end
  # /stories

  def easy_knowledge_stories_editable?
    if @easy_knowledge_stories
      !@easy_knowledge_stories.detect{|story| !story.editable?}
    elsif @story
      @story.editable?
    else
      false
    end
  end

  def render_easy_knowledge_story_tabs(easy_story)
    tabs = []

    tabs << { name: 'comments', label: l(:label_comment_plural), trigger: "EntityTabs.showTab(this)", partial: 'easy_knowledge_stories/tabs/comments' }

    url = easy_knowledge_stories_render_tabs_path(easy_story, tab: 'history')
    tabs << { name: 'history', label: l(:label_history), trigger: "EntityTabs.showAjaxTab(this, '#{url}')" }

    url = easy_knowledge_stories_render_tabs_path(easy_story, tab: 'readers')
    tabs << { name: 'readers', label: l(:label_readers), trigger: "EntityTabs.showAjaxTab(this, '#{url}')" }

    tabs
  end

end
