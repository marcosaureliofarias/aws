EasyExtensions::PatchManager.register_easy_page_controller 'EasyKnowledgeController'

EasyExtensions::PatchManager.register_easy_page_helper 'EasyKnowledgeHelper'

EpmEasyKnowledgeStoryQuery.register_to_all(:plugin => :easy_knowledge)

ActiveSupport.on_load(:easyproject, yield: true) do
  require 'easy_knowledge/proposer'
  require 'easy_knowledge/hooks'
  require 'easy_knowledge/internals'
  require 'easy_knowledge/permissions'

  Redmine::MenuManager.map :top_menu do |menu|
    menu.push :easy_knowledge, :easy_knowledge_overview_path, {
      :caption => :menu_easy_knowledge,
      :if => Proc.new { User.current.allowed_to_globally?(:view_easy_knowledge) },
      :after => Redmine::Plugin.installed?(:easy_alerts) ? :alerts : :users,
      :html => {:class => 'icon icon-bulb'}
    }
    menu.push(:easy_knowledge_new, :new_easy_knowledge_story_path, {
      :parent => :easy_knowledge,
      :if => Proc.new { User.current.allowed_to_globally?(:create_global_stories) },
      :caption => :label_easy_knowledge_new_story
    })
    menu.push(:easy_knowledge_favorited, {:controller => 'easy_knowledge_stories', :action => 'index', :set_filter => 1, :favorited => 1}, {
      :parent => :easy_knowledge,
      :if => Proc.new { User.current.allowed_to_globally?(:view_easy_knowledge) },
      :caption => :field_favorited
    })
  end

  Redmine::MenuManager.map :project_menu do |menu|
    menu.push :easy_knowledge,
              {:controller => 'easy_knowledge_projects', :action => 'index'},
              :param => :project_id,
              :caption => :easy_knowledge_project_menu,
              :if => Proc.new { |p| User.current.allowed_to_globally?(:view_easy_knowledge) && (User.current.allowed_to?(:manage_project_categories, p) || User.current.allowed_to?(:create_project_stories, p) || User.current.allowed_to?(:edit_project_stories, p) || User.current.allowed_to?(:edit_own_project_stories, p) || User.current.allowed_to?(:read_project_stories, p)) }
  end

  Redmine::MenuManager.map :easy_servicebar_items do |menu|
    menu.push :easy_knowledge_toolbar,
              {:controller => 'easy_knowledge', :action => 'show_toolbar'},
              :html => {
                :class => 'icon-bulb',
                :id => 'easy_knowledge_toolbar_trigger',
                :title => EasyExtensions::MenuManagerProc.new { I18n.t(:label_easy_knowledge) },
                :remote => true
              },
              :param => :project_id,
              :caption => '',
              :if => lambda { |project| User.current.allowed_to_globally?(:view_easy_knowledge) }
  end

end

EasyExtensions::AfterInstallScripts.add do
  page = EasyPage.where(:page_name => 'easy-knowledge-overview').first
  page_template = page.default_template

  unless page_template
    page_template = EasyPageTemplate.create(:easy_pages_id => page.id, :template_name => 'Default template', :description => 'Default template', :is_default => true)

    EasyPageTemplateModule.create_template_module(page, page_template, EpmEasyKnowledgeStoryQuery.first, 'top-left', HashWithIndifferentAccess.new(
      set_filter: '1',
      query_type: '2',
      query_name: I18n.t(:label_easy_knowledge_index_top_10),
      output: 'table',
      row_limit: '10',
      sort_criteria: {'0' => ['created_on', 'desc']},
      column_names: ['name', 'categories', 'tags', 'created_on'],
      show_sum_row: '0',
      load_groups_opened: '0',
      show_avatars: '1',
      chart_settings: {'primary_renderer' => 'line', 'axis_x_column' => 'name',
                       'legend_enabled' => '0', 'legend' => {'location' => 'nw'}},
      period_zoom: 'month',
      fields: ['created_on'],
      operators: {'created_on' => 'date_period_1'},
      values: {'created_on' => {'period' => 'in_past_n_days', 'period_days' => '30'}}
    ), 1)

    EasyPageTemplateModule.create_template_module(page, page_template, EpmTagCloud.first, 'top-left',
                                                  HashWithIndifferentAccess.new('easy_query_type' => EasyKnowledgeStoryQuery.name.underscore,
                                                                                'name' => I18n.t(:label_easy_knowledge_index_toptags),
                                                                                'row_limit' => '20'
                                                  ), 1)
  end

  EasyPageZoneModule.create_from_page_template(page_template) if !page.all_modules.exists?
end

RedmineExtensions::Reloader.to_prepare do

  require 'easy_knowledge/tree_utils'
  require 'easy_knowledge/easy_knowledge_global_category'

  CustomFieldsHelper::CUSTOM_FIELDS_TABS << {:name => EasyKnowledgeStoryCustomField.name, :partial => 'custom_fields/index', :label => :label_easy_knowledge_story_plural}

  # touch
  EasyKnowledgeProjectQuery
  EasyKnowledgeIssueQuery
  EasyKnowledgeCategoryQuery

  EasyQuery.map do |query|
    query.register 'EasyKnowledgeStoryQuery'
  end

  EasyExtensions::EasyProjectSettings.disabled_features[:suggester_search_types] << 'easy_knowledge_categories'

end

Redmine::Search.map do |search|
  search.register :easy_knowledge_stories
  search.register :easy_knowledge_categories
end
