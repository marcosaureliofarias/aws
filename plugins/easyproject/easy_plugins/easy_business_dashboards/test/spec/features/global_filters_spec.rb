require 'easy_extensions/spec_helper'

RSpec.feature 'Global filters', js: true, logged: :admin do

  let(:user_1) { FactoryBot.create(:user) }
  let(:user_2) { FactoryBot.create(:user) }
  let(:issue_this_year) { FactoryBot.create(:issue, assigned_to: user_1, start_date: Date.today) }
  let(:issue_prev_year) { FactoryBot.create(:issue, assigned_to: user_2, start_date: (Date.today-1.year)) }

  before(:each) do
    allow(EasyExtensions).to receive(:global_filters_enabled).and_return(true)
  end

  after(:each) do
    allow(EasyExtensions).to receive(:global_filters_enabled).and_call_original
  end

  # Add module "Tasks from filters"
  def add_issue_query_module
    first('.add-module-select option', text: I18n.t('easy_pages.modules.issue_query')).select_option
    wait_for_ajax
  end

  def add_trend_module(query_class)
    first('.add-module-select option', text: I18n.t('easy_pages.modules.trends')).select_option
    wait_for_ajax

    first('.easy-page-module .easy-query-type').find("option[value='#{query_class}']").select_option
    wait_for_ajax
  end

  def add_modules_and_filters
    find('.customize-button').click
    add_issue_query_module
    show_definitions

    @date_filter_id = add_global_filter(0, :label_date, 'DateGlobalFilter')
    @user_filter_id = add_global_filter(0, :label_user, 'UserGlobalFilter')
    @translatable_user_filter_id = add_global_filter(0, :label_user, 'I18n:')
    translatable_user_filter_label = EasyBusinessDashboardsController.new.send(:labels_for_easy_global_filters_hash).values.first

    assert_text('DateGlobalFilter', count: 1)
    assert_text('UserGlobalFilter', count: 1)
    expect(page).to have_css("select[name='global_filters[0][#{@translatable_user_filter_id}][name]'] option",
                             text: translatable_user_filter_label)

    # To check if filters are used even for newly added
    add_issue_query_module

    assert_text('DateGlobalFilter', count: 2)
    assert_text('UserGlobalFilter', count: 2)
    expect(page).to have_css('.query-global-filters td label', text: translatable_user_filter_label)

    select_options("select[data-filter-id='#{@date_filter_id}']", I18n.t('field_start_date'))
    select_options("select[data-filter-id='#{@user_filter_id}']", I18n.t('field_assigned_to'))

    save_easy_page_modules

    assert_text('DateGlobalFilter', count: 1)
    assert_text('UserGlobalFilter', count: 1)
    expect(page).to have_css('.global-filter__name', text: translatable_user_filter_label)
  end

  def add_global_filter(tab_id, type_name, name)
    # Global filters definition
    selector = %{.definition-global-filters[data-tab-id="#{tab_id}"]}
    # Add
    first("#{selector} select option", text: I18n.t(type_name)).select_option
    # Get filter id
    filter_id = evaluate_script("$('#{selector}').data('EASYGlobalFilters').filterIds").last
    # Set name
    find_field(name: "global_filters[#{tab_id}][#{filter_id}][name]").set(name)

    filter_id
  end

  def select_options(select, text)
    find_all("#{select} option", text: text).each(&:select_option)
  end

  def add_tab
    expect {
      find('.add-tab-button').click
      wait_for_ajax
    }.to change(EasyPageUserTab, :count).by(1)

    EasyPageUserTab.last.id
  end

  def set_global_filter(filter_id, value)
    find("select[name='global_filter_#{filter_id}'] option[value='#{value}']").select_option
  end

  def wait_for_schedule_late!(max_try: 10)
    # Easyautocomplete is in EASY.schedule.late
    execute_script(%{
      window.rspecReady = false
      EASY.schedule.late(function(){
        window.rspecReady = true
      })
    })

    # Wait untill queue is empty
    try = 1
    until evaluate_script("window.rspecReady")
      if try > max_try
        raise 'Too many trying'
      else
        sleep 0.1
      end

      try += 1
    end
  end

  def set_autocomplete_global_filter(filter_id, value, max_try: 10)
    wait_for_schedule_late!(max_try: max_try)

    # Queue should be empty so autocomplete is initialized
    execute_script("$('#global_filter_#{filter_id}').easymultiselect('setValue', ['#{value}'])")
  end

  def toggle_definition_state(selector, max_try: 10)
    execute_script("$('.definition-global-filter__state').click()")

    try = 1
    until first(selector)[:disabled] do
      if try > max_try
        raise 'Too many trying'
      else
        sleep 0.1
      end

      try += 1
    end
  end

  def apply_global_filters
    find('.global_filters__apply').click
    wait_for_ajax
  end

  def show_definitions
    execute_script("$('.definition-global-filters').show()")
  end

  it 'Normal page' do
    expect(Issue.count).to eq(0)
    issue_this_year
    issue_prev_year

    visit home_path

    add_modules_and_filters

    find_all('.entities').each do |entities|
      entities.assert_selector('.issue', count: 2)
      entities.assert_text(issue_this_year.subject)
      entities.assert_text(issue_prev_year.subject)
    end

    set_global_filter(@date_filter_id, 'current_year')
    apply_global_filters

    find_all('.entities').each do |entities|
      entities.assert_selector('.issue', count: 1)
      entities.assert_text(issue_this_year.subject)
      entities.assert_no_text(issue_prev_year.subject)
    end

    set_global_filter(@date_filter_id, 'last_year')
    apply_global_filters

    find_all('.entities').each do |entities|
      entities.assert_selector('.issue', count: 1)
      entities.assert_no_text(issue_this_year.subject)
      entities.assert_text(issue_prev_year.subject)
    end
  end

  it 'Template page' do
    my_page_template = EasyPageTemplate.find_by(template_name: 'my-page-template')
    visit easy_page_templates_show_page_template_path(id: my_page_template.id)

    add_modules_and_filters
  end

  it 'Tabs nightmare' do
    # On first visit, there are no tabs
    expect(EasyPageUserTab.count).to eq(0)

    visit home_path
    find('.customize-button').click

    non_tab_definition = %{.definition-global-filters[data-tab-id="0"]}
    show_definitions
    assert_selector(non_tab_definition)

    # 1. Create a global filter
    #    - there is no tab (tab.id == 0)
    date_filter_id = add_global_filter(0, :label_date, 'DateGlobalFilter')
    date_filter_select = %{select[data-filter-id="#{date_filter_id}"]}

    # 2. Create a page module
    #    - still doesn't belongs to any tab
    #    - new page module should have all global filters
    add_issue_query_module

    assert_selector(date_filter_select, count: 1)
    select_options(date_filter_select, I18n.t('field_start_date'))

    # 3. Create tab
    #    - definition and queries should change tab.id
    first_tab_id = add_tab

    first_tab_definition = %{.definition-global-filters[data-tab-id="#{first_tab_id}"]}
    assert_no_selector(non_tab_definition, visible: :all)
    assert_selector(first_tab_definition)
    assert_selector(date_filter_select, count: 1)

    # 4. Create a page module
    #    - tab.id != 0
    add_issue_query_module

    assert_selector(date_filter_select, count: 2)
    select_options(date_filter_select, I18n.t('field_start_date'))

    # 5. Create a global filter
    #    - should be registered to both page modules
    user_filter_id = add_global_filter(first_tab_id, :label_user, 'UserGlobalFilter')
    user_filter_select = %{select[data-filter-id="#{user_filter_id}"]}

    assert_selector(user_filter_select, count: 2)
    select_options(user_filter_select, I18n.t('field_assigned_to'))

    # 6. Add tab
    #    - Previous tab is still preset
    #    - Previous global filters cannot affect new tab
    second_tab_id = add_tab
    show_definitions

    second_tab_definition = %{.definition-global-filters[data-tab-id="#{second_tab_id}"]}
    assert_selector(first_tab_definition, visible: :hidden)
    assert_selector(second_tab_definition)

    # 7. Create global filter
    project_filter_id = add_global_filter(second_tab_id, :label_project, 'ProjectGlobalFilter')
    project_filter_select = %{select[data-filter-id="#{project_filter_id}"]}

    assert_selector(project_filter_select, count: 0)

    # 8. Create page module
    add_issue_query_module

    assert_selector(project_filter_select, count: 1)
    select_options(project_filter_select, I18n.t('field_project'))

    # 9. Save
    #    - Both tabs should be saved
    input_data = Hash.new { |hash, key| hash[key] = [] }
    find_all('select[data-filter-id]', visible: :all).each do |input|
      block_name, filter_id = input[:name].match(/([a-z0-9_]+)\[global_filters\]\[([0-9]+)\]/).captures
      input_data[filter_id] << input[:value]
    end

    expect(input_data[date_filter_id.to_s].size).to eq(2)
    expect(input_data[user_filter_id.to_s].size).to eq(2)
    expect(input_data[project_filter_id.to_s].size).to eq(1)

    # 10. Save all
    save_easy_page_modules

    # 11. Prepare data
    project1 = FactoryBot.create(:project, number_of_issues: 0, number_of_issue_categories: 0, number_of_subprojects: 0)
    project2 = FactoryBot.create(:project, number_of_issues: 0, number_of_issue_categories: 0, number_of_subprojects: 0)

    user1 = FactoryBot.create(:user)
    user2 = FactoryBot.create(:user)

    issue1 = FactoryBot.create(:issue, project: project1, assigned_to: user1, start_date: Date.today)
    issue2 = FactoryBot.create(:issue, project: project2, assigned_to: user2, start_date: (Date.today - 1.year))

    # 12. Check first tab
    visit home_path(t: 1)

    assert_text('DateGlobalFilter', count: 1)
    assert_text('UserGlobalFilter', count: 1)
    assert_no_text('ProjectGlobalFilter')

    find_all('.entities').each do |entities|
      entities.assert_selector('.issue', count: 2)
      entities.assert_text(issue1.subject)
      entities.assert_text(issue2.subject)
    end

    set_global_filter(date_filter_id, 'current_year')
    apply_global_filters

    find_all('.entities').each do |entities|
      entities.assert_selector('.issue', count: 1)
      entities.assert_text(issue1.subject)
      entities.assert_no_text(issue2.subject)
    end

    set_global_filter(date_filter_id, '')
    set_autocomplete_global_filter(user_filter_id, user2.id)
    apply_global_filters

    find_all('.entities').each do |entities|
      entities.assert_selector('.issue', count: 1)
      entities.assert_no_text(issue1.subject)
      entities.assert_text(issue2.subject)
    end

    # 13. Check second tab
    visit home_path(t: 2)

    assert_no_text('DateGlobalFilter')
    assert_no_text('UserGlobalFilter')
    assert_text('ProjectGlobalFilter', count: 1)

    find_all('.entities').each do |entities|
      entities.assert_selector('.issue', count: 2)
      entities.assert_text(issue1.subject)
      entities.assert_text(issue2.subject)
    end

    set_autocomplete_global_filter(project_filter_id, project1.id)
    apply_global_filters

    find_all('.entities').each do |entities|
      entities.assert_selector('.issue', count: 1)
      entities.assert_text(issue1.subject)
      entities.assert_no_text(issue2.subject)
    end

    # 14. Delete all filters
    #     - All filters from second page should be deleted
    find('.customize-button').click
    show_definitions
    within('.module-toggle-button') { find('.expander').click }

    toggle_definition_state(project_filter_select)
    save_easy_page_modules

    assert_no_text('DateGlobalFilter')
    assert_no_text('UserGlobalFilter')
    assert_no_text('ProjectGlobalFilter')

    visit home_path(t: 1)

    assert_text('DateGlobalFilter', count: 1)
    assert_text('UserGlobalFilter', count: 1)
    assert_no_text('ProjectGlobalFilter')
  end

  it 'Default values' do
    issue_this_year
    issue_prev_year

    visit home_path

    find('.customize-button').click
    add_issue_query_module
    show_definitions

    # Select
    date_filter_id = add_global_filter(0, :label_date, 'DateGlobalFilter')

    # Autocomplete
    user_filter_id = add_global_filter(0, :label_user, 'UserGlobalFilter')

    # Set default values
    select_options("[name='global_filters[0][#{date_filter_id}][default_value]']", I18n.t(:label_this_year))
    execute_script("$('#ac_user_#{user_filter_id}').easymultiselect('setValue', [#{user_1.id}])")

    date_filter_select = "select[data-filter-id='#{date_filter_id}']"
    user_filter_select = "select[data-filter-id='#{user_filter_id}']"

    # Set filters to query
    select_options(date_filter_select, I18n.t('field_start_date'))
    select_options(user_filter_select, I18n.t('field_assigned_to'))

    save_easy_page_modules

    # Select is pre-selected
    field = find_field(name: "global_filter_#{date_filter_id}")
    expect(field.value).to eq('current_year')

    # Autocomplete is pre-selected
    wait_for_schedule_late!
    values = evaluate_script("$('#global_filter_#{user_filter_id}').easymultiselect('getValue')")
    expect(values.first.to_i).to eq(user_1.id)

    # By defaults, global filters should be set
    # Only 1 issue should be returned
    find_all('.entities').each do |entities|
      entities.assert_selector('.issue', count: 1)
      entities.assert_text(issue_this_year.subject)
      entities.assert_no_text(issue_prev_year.subject)
    end
  end

  # Currencies are maybe cached and it breaks (sometines) other tests
  xit 'Currency' do
    currency1 = FactoryBot.create(:easy_currency, :czk, activated: true)
    currency2 = FactoryBot.create(:easy_currency, :eur, activated: true)

    EasyCurrency.reinitialize_tables

    with_easy_settings(easy_currencies_initialized: true) do
      visit home_path
      find('.customize-button').click
      show_definitions

      # Activate global currency
      find('[id^=global_currency]').check

      # Add query with price column
      add_trend_module(EasyCrmCaseQuery)

      # Check sum (currency is useless on count)
      find('.easy-page-module [name$="\[type\]"][value="sum"]').choose

      # Sum price column
      find('.easy-page-module [name$="\[column_to_sum\]"] option', text: EasyCrmCase.human_attribute_name(:price)).select_option

      save_easy_page_modules

      # Price is 0 but should be curency-less
      find('.easy-trend__data').assert_no_text(currency1.symbol)
      find('.easy-trend__data').assert_no_text(currency2.symbol)

      # Activate one currency
      find('[name="global_currency"] option', text: currency1.name).select_option
      apply_global_filters

      # Price should be with currency
      find('.easy-trend__data').assert_text(currency1.symbol)
      find('.easy-trend__data').assert_no_text(currency2.symbol)
    end

    # Because its currencies
    EasyCurrency.reinitialize_tables(true)
    EasyCurrency.destroy_all
  end

  context 'with user select me and subordinates', skip: !Redmine::Plugin.installed?(:easy_org_chart) do

    # Find first module and get uniq_id
    def get_module_uniq_id
      page.first('.module-content')[:id]
    end

    def select_options_by_value(select, value)
      find_all("#{select} option[value='#{value}']").each(&:select_option)
    end

    def add_trend_modules(entities)
      entities.each do |entity|
        add_trend_module(entity)
        @module_unig_ids[entity] = get_module_uniq_id
        find("##{@module_unig_ids[entity]}_type_count").choose()
      end
    end

    # Expected that trends show count entities
    def all_trends_show_entity_count(entities, count)
      entities.each do |entity|
        expect(find("##{@module_unig_ids[entity]}").text).to eq(count)
      end
    end

    def set_global_filter_and_apply(filter_id, value)
      set_autocomplete_global_filter(filter_id, value)
      find('.global_filters__apply').click
      wait_for_ajax
    end

    scenario 'with me and subordinates' do
      # 0. Prepare data
      @module_unig_ids = {}
      entities = %w(EasyIssueQuery EasyProjectQuery EasyTimeEntryQuery)

      user1 = FactoryBot.create(:user)
      user2 = FactoryBot.create(:user)

      me_project = FactoryBot.create(:project, number_of_issues: 0, number_of_issue_categories: 0, number_of_subprojects: 0, author: User.current)
      project1 = FactoryBot.create(:project, number_of_issues: 0, number_of_issue_categories: 0, number_of_subprojects: 0, author: user1)
      project2 = FactoryBot.create(:project, number_of_issues: 0, number_of_issue_categories: 0, number_of_subprojects: 0, author: user2)

      me_issue = FactoryBot.create(:issue, project: me_project, author: User.current, start_date: Date.today)
      issue1 = FactoryBot.create(:issue, project: project1, author: user1, start_date: Date.today)
      issue2 = FactoryBot.create(:issue, project: project2, author: user2, start_date: (Date.today - 1.year))

      if Redmine::Plugin.installed?(:easy_attendances)
        entities << 'EasyAttendanceQuery'

        me_attendnace = FactoryBot.create(:easy_attendance, user: User.current)
        attendace1 = FactoryBot.create(:easy_attendance, user: user1)
        attendace2 = FactoryBot.create(:easy_attendance, user: user2)
      end

      me_time_entry = FactoryBot.create(:time_entry, user: User.current, project: me_project, issue: me_issue)
      time_entry1 = FactoryBot.create(:time_entry, user: user1, project: project1, issue: issue1)
      time_entry2 = FactoryBot.create(:time_entry, user: user2, project: project2, issue: issue2)

      node1 = EasyOrgChartNode.create(user_id: User.current.id, parent_id: nil)
      node2 = EasyOrgChartNode.create(user_id: user1.id, parent_id: node1.id, root_id: node1.id)
      node3 = EasyOrgChartNode.create(user_id: user2.id, parent_id: node2.id, root_id: node1.id)
      EasyOrgChart::Tree.clear_cache

      visit '/my/page_layout'

      # 1. Create and set Global filter
      show_definitions
      user_filter_id = add_global_filter(0, :label_user, 'UserGlobalFilter')
      user_filter_select = %{select[data-filter-id="#{user_filter_id}"]}
      # 2. Create and set trend modules
      add_trend_modules(entities)

      # 3. Set Global filters on modules
      select_options_by_value(user_filter_select, 'author_id')
      select_options_by_value(user_filter_select, 'user_id')

      # 4. Save all
      save_easy_page_modules

      # 5. Check before application global filter
      #   Expected that modules show count entities.
      #   In that case every 3.
      #   Because every entity is three times.
      all_trends_show_entity_count(entities, '3')

      # 6. Set global filter on << me >> and apply
      set_global_filter_and_apply(user_filter_id, 'me')
      #   Expected that modules show count entities.
      #   In that case every 1.
      #   Because me have one from each entity.
      all_trends_show_entity_count(entities, '1')

      # 7. Set global filter on << my subordinates >> and apply
      set_global_filter_and_apply(user_filter_id, 'my_subordinates')
      #   Expected that modules show count entities.
      #   In that case every 1.
      #   Because I have one direct subordinate who has one from each entity
      all_trends_show_entity_count(entities, '1')

      # 10. Set global filter on << my subordinates tree >> and apply
      set_global_filter_and_apply(user_filter_id, 'my_subordinates_tree')
      #   Expected that modules show count entities.
      #   In that case every 2.
      #   Because I have two subordinates who have each one of each entity.
      all_trends_show_entity_count(entities, '2')
    end
  end
end
