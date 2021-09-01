module EasyKnowledgeHelper

  def get_grouped_categories
    grouped_categories = []
    grouped_categories << [l(:label_easy_knowledge_index_user), EasyKnowledgeCategory.category_by_user(User.current.id).pluck(:name, :id)] if User.current.allowed_to_globally?(:manage_own_personal_categories)
    grouped_categories << [l(:label_easy_knowledge_index_global), EasyKnowledgeCategory.global.pluck(:name, :id)] if User.current.allowed_to_globally?(:manage_global_categories)
    # get_easy_knowledge_projects.each do |project|
    #   category = EasyKnowledgeCategory.category_by_project(project.id)
    #   next if category.blank?
    #   grouped_categories << [l(:label_easy_knowledge_index_project)+"(#{project.family_name(:separator => ' > ')})", category]
    # end
    grouped_categories << [l(:label_easy_knowledge_index_project)+"(#{@project.family_name(separator: ' > ')})", @project.easy_knowledge_categories.pluck(:name, :id)] if @project

    return grouped_categories
  end

  def get_easy_knowledge_projects
    knowledge_projects = Project.visible.has_module(:easy_knowledge).where("#{Project.allowed_to_condition(User.current, :manage_project_categories)} OR #{Project.allowed_to_condition(User.current, :read_project_stories)}").preload(:easy_knowledge_categories).to_a
    ancestor_conditions = knowledge_projects.collect{|project| "(#{Project.quoted_left_column_name} < #{project.lft} AND #{Project.quoted_right_column_name} > #{project.rgt})"}
    knowledge_parents = ancestor_conditions.any? ? Project.preload(:easy_knowledge_categories).where(ancestor_conditions.join(' OR ')): []
    (knowledge_projects | knowledge_parents).sort_by(&:lft)
  end

  def get_tags
    ActsAsTaggableOn::Tag.joins(:taggings).distinct.where(:taggings => {:context => 'tags'}).order(:name).pluck(:name)
  end

  # Renders a list of all categories
  # Pass a category show link as category_link_block
  # Example:
  # <% render_easy_knowledge_categories(EasyKnowledgeCategory.visible) do |category| %>
  # <%= link_to category.name, {} -%>
  # <% end -%>
  def render_easy_knowledge_categories(categories, options = {}, category_name_link_block = nil, category_buttons_block1 = nil, category_buttons_block2 = nil, category_description_block = nil)
    concat(render(:partial => 'easy_knowledge_categories/categories_list',
        :locals => {:categories => categories,
          :category_name_link_block => category_name_link_block,
          :category_buttons_block1 => category_buttons_block1,
          :category_buttons_block2 => category_buttons_block2,
          :category_description_block => category_description_block}.merge(options)))
  end

  def easy_knowledge_project_categories_tree(categories, ul_options = {})
    return '' if categories.blank?

    tree = content_tag(:ul, ul_options) do
      categories.each do |category|
        item = "<li><div>" + link_to(category.name + " (#{category.stories.count})", easy_knowledge_project_path(category), :title => l(:title_easy_knowledge_category_stories)) + "</div>"
        item << easy_knowledge_project_categories_tree(category.children, :class => 'category-list')
        item << "</li>"

        concat item.html_safe
      end
    end
    tree
  end

  def render_api_category(api, category)
    api.category do
      api.id category.id
      api.name category.name
      api.description category.description
      api.created_on category.created_on
      api.updated_on category.updated_on
      api.author_id category.author_id
      api.parent_id category.parent_id
      api.entity_type category.entity_type
      api.entity(id: category.entity.id) do
        api.name category.entity.to_s
        api.type category.entity_type
      end if category.entity
    end
  end

  def render_api_shell_story(api, story)
    api.story do
      api.id story.id
      api.name story.name
      api.created_on story.created_on
      api.updated_on story.updated_on
      api.author_id story.author_id
    end
  end

  def render_api_knowledge_urls(api)
    api.urls do

      api.knowledgeData easy_knowledge_data_path(format: 'json')
      api.renderTabs easy_knowledge_stories_render_tabs_path(':storyID')
      api.markAsRead easy_knowledge_story_mark_as_read_path(format: 'json')
      api.getLangfies easy_knowledge_all_langfiles_path(format: 'json')

      api.categoryCreate easy_knowledge_categories_path(format: 'json')
      api.categoryUpdate easy_knowledge_category_path(':categoryID', format: 'json')
      api.categoryDelete easy_knowledge_global_path(':categoryID', format: 'json')

      api.storyCreate easy_knowledge_stories_path(format: 'json')

      api.getStoryEdit edit_easy_knowledge_story_path(':storyID')
      api.getStoryShow show_partial_easy_knowledge_story_path(':storyID', layout: false)


      api.storyUpdate easy_knowledge_story_path(':storyID', format: 'json')
      api.storyDelete easy_knowledge_story_path(':storyID', format: 'json')
      api.postStoryAddLike add_to_favorite_easy_knowledge_story_path(':storyID')
      api.postStoryRemoveLike remove_from_favorite_easy_knowledge_story_path(':storyID')
      api.getStoryRestore easy_knowledge_story_restore_path(':storyID')

      api.getProjectShowAsTree easy_knowledge_project_show_as_tree_path(':projectID', ':storyID')
      api.update_story_category easy_knowledge_story_update_story_category_path(':storyID', format: 'json')

      api.print url_for(controller: 'easy_printable_templates', action: 'template_chooser',
        entity_type: 'EasyKnowledgeStory', entity_id: '__storyID',
        back_url: @project ? easy_knowledge_story_path(@project, '__storyID') : easy_knowledge_story_path('__storyID'))

    end
  end

  def render_api_knowledge_lang_files(api)
    lang_array = [
        :label_easy_knowledge_index_user,
        :label_easy_knowledge_index_project,
        :field_name,
        :field_author,
        :label_not_story_selected,
        :label_comment_plural,
        :label_history,
        :label_readers,
        :label_easy_knowledge_story,
        :label_easy_knowledge_new_story,
        :error_no_story_seleted,
        :tab_easy_knowledge_categories,
        :button_easy_knowledge_new_category,
        :label_easy_knowledge_discard,
        :label_easy_knowledge_categories_and_stories,
        :label_easy_knowledge_story_unclassified,
        :tab_knowledge_db_personal,
        :tab_knowledge_db_tree,
        :tab_knowledge_db_favorites,
        :warning_easy_knowledge_category_edit_unsaved,
        :button_easy_knowledge_stories_assign_to_easy_kb_category,
        :button_easy_knowledge_stories_remove_from_category,
        :label_easy_knowledge_manage_categories,
        :notice_you_have_added_to_category,
        :notice_you_have_removed_from_category,
        :title_link_journal
    ]
    api.knowledge_lang_files Hash[ *lang_array.collect { |v| [ v, l(v) ] }.flatten ]
  end

end
