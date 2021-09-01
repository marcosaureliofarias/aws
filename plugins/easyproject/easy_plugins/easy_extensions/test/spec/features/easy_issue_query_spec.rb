require 'easy_extensions/spec_helper'

feature 'easy issue query', :js => true, :logged => :admin do

  context 'project' do
    let(:project1) { FactoryGirl.create(:project, :with_subprojects, :number_of_subprojects => 1, :enabled_module_names => ['issue_tracking'], :number_of_issues => 2) }
    let(:project2) { FactoryGirl.create(:project, :number_of_issues => 1) }

    scenario 'grouped' do
      visit project_issues_path(project1, :set_filter => 1, :group_by => 'status')
      status_count = project1.issues.group_by { |i| i.status_id }.keys.count
      expect(page).to have_css('.list .group', :count => status_count)
    end

    scenario 'ignore group_to_load' do
      project1
      project2
      visit issues_path(set_filter: '1', group_by: 'project', group_to_load: [project2.id.to_s])
      wait_for_ajax
      page.find("tr.group[data-group-name^='\[\"#{project1.id.to_s}'] span.expander").click
      wait_for_ajax
      expect(page).to have_selector('table.entities tbody tr.issue', count: 2)
      page.find("tr.group[data-group-name^='\[\"#{project2.id.to_s}'] span.expander").click
      wait_for_ajax
      expect(page).to have_selector('table.entities tbody tr.issue', count: 3)
    end

    scenario 'filter by subproject' do
      project2
      visit project_issues_path(project1, :set_filter => 1, :subproject_id => '*')

      expect(page).to have_selector('table.entities tbody tr', :count => 3)
    end
  end

  context 'invalid query' do
    let(:locked_user) { FactoryGirl.create(:user, :status => 3) }
    let!(:issue) { FactoryGirl.create(:issue, :subject => 'Issue of locked', :assigned_to => locked_user) }

    scenario 'display invalid query' do
      visit issues_path(:set_filter => 1, :assigned_to_id => "=#{locked_user.id}")

      expect(page).to have_text('Issue of locked')
    end
  end

  context 'select most used columns' do
    before(:each) do
      visit issues_path(:set_filter => '1', :column_names => ['author'])
      visit issues_path
      page.find('#easy-query-toggle-button-settings').click
      expect(page).to have_css("#available_columns option[value='author']", :count => 2)
      expect(page).not_to have_css("#available_columns option[value='author'][disabled='disabled']")
    end

    after(:each) do
      page.find('#modal_selector_move_column_right_button').click
      page.all("#available_columns option[value='author']").each { |column| expect(column.disabled?).to eq(true) }
      expect(page).to have_css("#available_columns option[value='author']", :count => 2)
      expect(page).to have_css("#selected_columns option[value='author']", :count => 1)
      page.all("#selected_columns option[value='author']").each { |column| expect(column.disabled?).to eq(false) }
      page.execute_script("$(\"#selected_columns option[value=\'author\']\").attr('selected', 'selected')")
      page.find('#modal_selector_move_column_left_button').click
      expect(page).not_to have_css("#selected_columns option[value='author']")
      expect(page).to have_css("#available_columns option[value='author']", :count => 2)
      page.all("#available_columns option[value='author']").each { |column| expect(column.disabled?).to eq(false) }
    end

    scenario 'all' do
      page.execute_script("$(\"#available_columns option[value=\'author\']\").attr('selected', 'selected')")
    end

    scenario 'first' do
      page.execute_script("$(\"#available_columns option[value=\'author\']:first\").attr('selected', 'selected')")
    end
  end

  context 'issue categories' do
    let!(:project) { FactoryGirl.create(:project, :enabled_module_names => ['issue_tracking'], :number_of_issues => 0) }
    let!(:issue_category) { FactoryGirl.create(:issue_category, :project => project) }
    let!(:issue_category_root) { FactoryGirl.create(:issue_category, :project => project) }
    let!(:issue_category_child) { FactoryGirl.create(:issue_category, :project => project, :parent => issue_category_root) }
    let!(:issue1) { FactoryGirl.create(:issue, :category => issue_category, :project => project) }
    let!(:issue2) { FactoryGirl.create(:issue, :category => issue_category_root, :project => project) }
    let!(:issue3) { FactoryGirl.create(:issue, :category => issue_category_child, :project => project) }

    #scenario 'group by root' do
    #  visit project_issues_path(project, :set_filter => 1, :group_by => 'root_category')
    #  expect(page).to have_css('.list .group', :count => 1, :text => issue_category)
    #  expect(page).to have_css('.list .group', :count => 1, :text => issue_category_root)
    #  expect(page).not_to have_css('.list .group', :text => issue_category_child)
    #end

    scenario 'group by parent' do
      visit project_issues_path(project, :set_filter => 1, :group_by => 'parent_category')
      expect(page).to have_css('.list .group', :count => 1, :text => issue_category_root)
      expect(page).not_to have_css('.list .group', :text => issue_category_child)
      expect(page).not_to have_css('.list .group', :text => issue_category)
    end

    scenario 'group by category' do
      visit project_issues_path(project, :set_filter => 1, :group_by => 'category')
      expect(page).to have_css('.list .group .attribute__list.attribute__list--tree span', :count => 1, :text => issue_category_root)
      expect(page).to have_css('.list .group .attribute__list.attribute__list--tree span', :count => 1, :text => issue_category_child)
      expect(page).to have_css('.list .group', :count => 1, :text => issue_category_child)
      expect(page).to have_css('.list .group', :count => 1, :text => issue_category)
    end
  end

  context 'parent issue' do
    let(:project) { FactoryGirl.create(:project, enabled_module_names: ['issue_tracking'], number_of_issues: 0) }
    let(:issue1) { FactoryGirl.create(:issue, project: project) }
    let(:issue2) { FactoryGirl.create(:issue, project: project, parent: issue1) }

    scenario 'groups' do
      issue2
      visit issues_path(set_filter: '1', column_names: ['subject'], group_by: 'parent', load_groups_opened: '1')
      wait_for_ajax
      expect(page).to have_css('tr.group[data-group-name="[\"\"]"]')
      expect(page).to have_css("tr.group[data-group-name='[\"#{issue1.id}\"]']")
      expect(page).not_to have_css("tr.group[data-group-name='[\"#{issue2.id}\"]']")

      expect(page).to have_css("table.entities tbody tr#entity-#{issue1.id}")
      expect(page).to have_css("table.entities tbody tr#entity-#{issue2.id}")
    end
  end

  context 'grouped by' do
    let!(:project) { FactoryGirl.create(:project, enabled_module_names: ['issue_tracking'], number_of_issues: 0) }
    let!(:cf_datetime_filter) { FactoryGirl.create(:issue_custom_field, field_format: 'datetime', is_for_all: true, is_filter: true, trackers: project.trackers, max_length: 25) }
    let!(:cf_datetime_non_filter) { FactoryGirl.create(:issue_custom_field, field_format: 'datetime', is_for_all: true, is_filter: false, trackers: project.trackers, max_length: 25) }
    let!(:issue1) { FactoryGirl.create(:issue, project: project, due_date: nil) }
    let!(:issue2) do
      _issue = FactoryGirl.create(:issue, project: project, due_date: Date.today)
      _issue.reload
      _issue.custom_field_values = {
          cf_datetime_filter.id.to_s     => { date: Date.today, hour: 10, minute: 10 },
          cf_datetime_non_filter.id.to_s => { date: Date.today, hour: 10, minute: 10 }
      }
      _issue.save!
      _issue
    end
    let(:periods) { %w(day week month quarter year) }
    let(:week_starts) { %w(1 6 7) } # 1 - Monday, 6 - Saturday, 7 - Sunday
    let(:date_string) { proc { |period|
      if period == 'week'
        Date.today.beginning_of_week(EasyUtils::DateUtils.day_of_week_start).strftime('%Y-%m-%d')
      else
        Date.today.send("beginning_of_#{period}").strftime('%Y-%m-%d')
      end
    } }

    def test_with_period(period)
      page.find("tr.group[data-group-name^='\[\"#{date_string.call(period)}'] span.expander").click
      wait_for_ajax
      expect(page).to have_css("table.entities tbody tr#entity-#{issue2.id}")
      expect(page).not_to have_css("table.entities tbody tr#entity-#{issue1.id}")
      page.find('tr.group[data-group-name="\[\"\"\]"] span.expander').click
      wait_for_ajax
      expect(page).to have_css("table.entities tbody tr#entity-#{issue1.id}")
    end

    scenario 'due date' do
      periods.each do |period|
        if period == 'week'
          week_starts.each do |start|
            with_settings(start_of_week: start) do
              visit issues_path(set_filter: '1', column_names: %w(subject due_date), group_by: 'due_date', period_zoom: period, load_groups_opened: '0')

              test_with_period(period)
            end
          end
        else
          visit issues_path(set_filter: '1', column_names: %w(subject due_date), group_by: 'due_date', period_zoom: period, load_groups_opened: '0')

          test_with_period(period)
        end
      end
    end

    scenario 'datetime filter cf' do
      cf_name = "cf_#{cf_datetime_filter.id}"
      periods.each do |period|
        visit issues_path(set_filter: '1', column_names: ['subject', cf_name], group_by: cf_name, period_zoom: period, load_groups_opened: '0')

        test_with_period(period)
      end
    end

    scenario 'datetime non-filter cf' do
      cf_name = "cf_#{cf_datetime_non_filter.id}"
      periods.each do |period|
        visit issues_path(set_filter: '1', column_names: ['subject', cf_name], group_by: cf_name, period_zoom: period, load_groups_opened: '0')

        test_with_period(period)
      end
    end
  end

  context 'date cf' do
    let(:project) { FactoryGirl.create(:project, enabled_module_names: ['issue_tracking'], number_of_issues: 0) }
    let(:cf_date) { FactoryGirl.create(:issue_custom_field, field_format: 'date', is_for_all: true, is_filter: true, trackers: project.trackers, max_length: 25) }

    def create_issue_with_date_cf(date)
      _issue = FactoryGirl.create(:issue, project: project)
      _issue.reload
      _issue.custom_field_values = {
          cf_date.id.to_s => date,
      }
      _issue.save!
      _issue
    end

    let(:issues) do
      period_start = Date.today.beginning_of_month
      10.times { |i| create_issue_with_date_cf(period_start.advance(:months => i)) }
      5.times { |i| create_issue_with_date_cf(period_start.advance(:days => i)) } # same group
      true
    end

    scenario 'groups' do
      cf_name = "cf_#{cf_date.id}"
      issues
      path = issues_path(set_filter: '1', column_names: ['subject', cf_name], sort: "cf_#{cf_date.id}", group_by: cf_name, period_zoom: 'month', load_groups_opened: '0')
      with_settings(:per_page_options => '5') do
        visit path
        expect(page).to have_css('tr.group', :count => 5)
        expect(page.find('#easy-query-heading-count')).to have_content(15)
      end

      with_settings(:per_page_options => '25') do
        visit path
        expect(page).to have_css('tr.group', :count => 10)
        expect(page.find('#easy-query-heading-count')).to have_content(15)
      end
    end

    scenario 'sums' do
      cf_name = "cf_#{cf_date.id}"
      issues
      Issue.last.update_attribute(:estimated_hours, 5)
      EasyExtensions::EasyQueryHelpers::PeriodSetting::ALL_PERIODS.each do |period|
        visit issues_path(set_filter: '1', column_names: ['subject', cf_name, 'estimated_hours'], group_by: cf_name, period_zoom: period, load_groups_opened: '0')
        wait_for_ajax
        expect(page).to have_css(".estimated_hours [data-value='5.0']")
      end
    end
  end

  context 'outputs' do
    let(:chart_settings) do
      {
          'primary_renderer' => 'bar',
          'axis_x_column'    => 'project',
          'axis_y_type'      => 'count',
          'axis_y_column'    => 'estimated_hours',
          'bar_direction'    => 'vertical',
          'legend_enabled'   => '0',
          'legend'           => {},
          'location'         => 'nw'
      }
    end
    let(:kanban_settings) do
      {
          'kanban_group'          => 'tracker',
          'main_attribute'        => 'project',
          'summable_column'       => 'spent_hours',
          'kanban_group_trackers' => Tracker.pluck(:id).map(&:to_s)
      }
    end
    let(:easy_issue_query) { FactoryGirl.build(:easy_issue_query) }
    let!(:issue) { FactoryGirl.create(:issue) }

    scenario 'chart + list' do
      easy_issue_query.chart_settings = chart_settings
      easy_issue_query.outputs        = ['chart', 'list']
      easy_issue_query.save!
      visit issues_path(query_id: easy_issue_query.id)
      wait_for_ajax
      expect(page).to have_css('#easy_query_chart')
      page.find('#easy-query-toggle-button-settings').click
      expect(page.find(".chart-type-select input[value='bar']").checked?).to eq(true)
      expect(page).to have_css("tr#entity-#{issue.id}")
    end

    scenario 'chart' do
      easy_issue_query.chart_settings = chart_settings
      easy_issue_query.outputs        = ['chart']
      easy_issue_query.save!
      visit issues_path(query_id: easy_issue_query.id)
      wait_for_ajax
      expect(page).to have_css('#easy_query_chart')
      page.find('#easy-query-toggle-button-settings').click
      expect(page.find(".chart-type-select input[value='bar']").checked?).to eq(true)
    end

    scenario 'chart with legend' do
      easy_issue_query.chart_settings = chart_settings.merge({'legend_enabled' => '1', 'primary_renderer' => 'pie', 'legend' => {'location' => 's'}})
      easy_issue_query.outputs        = ['chart']
      easy_issue_query.save!
      visit issues_path(query_id: easy_issue_query.id)
      wait_for_ajax
      expect(page).to have_css('#easy_query_chart')
      expect(page).to have_css('.c3-legend')
    end

    scenario 'tiles' do
      easy_issue_query.outputs = ['tiles']
      easy_issue_query.save!
      visit issues_path(query_id: easy_issue_query.id)
      wait_for_ajax
      expect(page).to have_css('.easy-entity-card-container')
    end

    scenario 'calendar' do
      easy_issue_query.outputs = ['calendar']
      easy_issue_query.save!
      visit issues_path(query_id: easy_issue_query.id)
      wait_for_ajax
      expect(page).to have_css('#issuescalendar-container')
    end

    scenario 'kanban' do
      easy_issue_query.outputs            = ['kanban']
      easy_issue_query.settings['kanban'] = kanban_settings
      easy_issue_query.save!
      visit issues_path(query_id: easy_issue_query.id)
      wait_for_ajax
      expect(page).to have_css('#issueskanban-placeholder')
      expect(page).to have_css(".agile__item.item_#{issue.id}")
    end if Redmine::Plugin.installed?(:easy_agile_board)
  end

  context 'pagination' do
    scenario 'query params' do
      FactoryBot.create_list(:issue, 2)
      with_settings(per_page_options: '1') do
        with_user_pref(disable_automatic_loading: '1') do
          visit issues_path(set_filter: 1, column_names: ['subject'])
          wait_for_ajax
          expect(page).to have_css('.entities tr.issue', count: 1)
          expect(page).to have_css(".entities tr.issue input[type='checkbox']", count: 1)
          page.find('.infinite-scroll-load-next-page-trigger-container > a').click
          wait_for_ajax
          expect(page).to have_css('.entities tr.issue', count: 2)
          expect(page).to have_css(".entities tr.issue input[type='checkbox']", count: 2)
        end
      end
    end

    scenario 'groups' do
      FactoryBot.create_list(:issue, 3)
      with_settings(per_page_options: '1') do
        with_user_pref(disable_automatic_loading: '1') do
          visit issues_path(set_filter: 1, column_names: ['subject'], group_by: 'project')
          wait_for_ajax
          expect(page).to have_css('.entities tr.group', count: 1)
          page.find('.infinite-scroll-load-next-page-trigger-container > a').click
          wait_for_ajax
          expect(page).to have_css('.entities tr.group', count: 2)
          page.find('.infinite-scroll-load-next-page-trigger-container > a').click
          wait_for_ajax
          expect(page).to have_css('.entities tr.group', count: 3)
          expect(page).not_to have_css('.infinite-scroll-load-next-page-trigger-container > a')
        end
      end
    end
  end

  scenario 'save tagged color' do
    query_name = 'saved query'
    visit new_easy_query_path(:type => 'EasyIssueQuery', :easy_query => { :name => query_name })
    wait_for_ajax
    page.find('#easy_query_is_tagged').set(true)
    page.find('#settings_tagged_color option[value=\'palette-9\']').select_option
    page.find('.form-actions input[type=\'submit\']').click
    sidebar_closed = page.has_css?('.nosidebar')
    if sidebar_closed
      page.find(".sidebar-control > a").click
    end
    expect(page).to have_css('.easy-query-heading .icon.palette-9')
    expect(page.find('.saved-queries')).to have_content(query_name)
    visit edit_easy_query_path(:id => EasyQuery.find_by(:name => query_name).id.to_s)
    expect(page).to have_css("input[value='#{query_name}']")
    expect(page.find('#easy_query_is_tagged')).to be_checked
    tagged_color = page.find('#settings_tagged_color')
    expect(tagged_color.value).to eq('palette-9')
    expect(tagged_color).to have_css('.palette-9')
  end
end
