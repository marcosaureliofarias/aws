require 'easy_extensions/spec_helper'

feature 'easy project query view', js: true, logged: :admin do

  def open_settings
    page.find('#easy-query-toggle-button-settings').click
    wait_for_ajax
  end

  def select_group_by(group_name)
    page.execute_script("$('#group_by input.ui-autocomplete-input').easymultiselect('setValue', ['#{group_name}']);")
  end

  def apply_settings
    page.find('#filter_buttons .apply-link').click
    wait_for_ajax
  end

  let!(:projects) { FactoryBot.create_list(:project, 3) }
  let(:project_cf) { FactoryBot.create(:project_custom_field, field_format: 'string') }
  let(:project) { FactoryBot.create(:project, custom_field_values: { "#{project_cf.id}" => 'test_cf' }) }

  scenario 'group by author' do
    visit projects_path
    wait_for_ajax
    open_settings
    select_group_by('author')
    apply_settings
    expect(page.find('.list.projects')).to have_content(projects.first.author.to_s)
  end

  scenario 'group by cf' do
    project
    visit settings_project_path(projects.first)
    cv = 'test group'
    page.find("#project_custom_field_values_#{project_cf.id}_#{projects.first.id}").set(cv)
    page.find('#save-project-info').click

    visit projects_path
    wait_for_ajax
    open_settings
    select_group_by("cf_#{project_cf.id}")
    apply_settings
    expect(page.find('.list.projects')).to have_content(cv)
  end

  scenario 'selected columns are disabled' do
    visit projects_path
    wait_for_ajax
    open_settings
    available_column = page.find("#available_columns option[value='name']")
    selected_column  = page.find("#selected_columns option[value='name']")
    expect(available_column).to be_disabled
    expect(selected_column).not_to be_disabled
  end

  scenario 'show expanders' do
    projects.last.update_attribute(:parent_id, projects.first.id)
    # default
    visit projects_path
    expect(page.find('table.list.projects')).to have_css('.project-parent-expander', count: 1)
    # all columns
    visit projects_path(set_filter: '1', easy_query: { columns_to_export: 'all' })
    expect(page.find('table.list.projects')).to have_css('.project-parent-expander', count: 1)
  end

  feature 'query filter' do
    let(:default_filter) do
      {
        'easy_project_query_default_filters' => { :is_closed => { :operator => '=', :values => [0] } }
      }
    end

    context 'when default filters are set' do
      context 'when not changed by user' do
        scenario 'should have label "default"' do
          expect_default_filter
        end
      end

      context 'when changed by user' do
        scenario 'should have label "active"' do
          with_easy_settings(default_filter) do
            visit projects_path(set_filter: 1, is_closed: '=0', favorited: '=1')

            expect(page).to have_css('div#easy-query-toggle-button-filters span.active-filter')
          end
        end
      end

      context 'when unset to no filters' do
        scenario 'should have no label' do
          with_easy_settings(default_filter) do
            visit projects_path(set_filter: 1)

            expect(page).not_to have_css('div#easy-query-toggle-button-filters span')
          end
        end
      end
    end

    context 'when no default filters and filter not changed by user' do
      scenario 'should have label "default"' do
        expect_default_filter
      end
    end

    def expect_default_filter
      with_easy_settings(default_filter) do
        visit projects_path

        expect(page).to have_css('div#easy-query-toggle-button-filters span.default-filter')
      end
    end
  end
end

feature 'easy project query view', js: true, logged: :admin do

  let(:project_cf) { FactoryBot.create(:project_custom_field, id: 999, field_format: 'string') }
  let(:project) { FactoryBot.create(:project, custom_field_values: { "#{project_cf.id}" => 'test_cf' }) }

  cf_name = 'cf_999'
  let(:default_filter) do
    {
      'easy_project_query_default_sorting_array' => [[cf_name, 'asc']]
    }
  end

  scenario 'order by cf' do
    project
    with_easy_settings(default_filter) do
      visit projects_path
      expect(page).to have_content(I18n.t(:label_project_index))
    end
  end

  context 'load group' do
    let!(:project1) { FactoryBot.create(:project, created_on: Date.new(2020,1,1)) }
    let!(:project2) { FactoryBot.create(:project, created_on: Date.new(2020,1,15)) }

    scenario 'by date with the same filter' do
      visit projects_path(group_by: 'created_on', created_on: '2020-01-01|2020-01-02', load_groups_opened: '1')
      wait_for_ajax
      expect(page).to have_css('.easy-entity-list__item-group-control', count: 1)
      expect(page).to have_css('.easy-entity-list__item-attribute.name', count: 1)
    end
  end
end

feature 'easy query module', js: true, logged: :admin do
  let!(:project) { FactoryBot.create(:project) }
  let!(:chart_settings) do
    {
      "primary_renderer" => "line", "axis_x_column" => "created_on",
      "axis_y_type"      => "sum", "axis_y_column" => "sum_estimated_hours",
      "y_label"          => "", "secondary_axis_y_column" => "", "period_column" => "created_on",
      "bar_direction"    => "vertical", "bar_limit" => "0", "bar_reverse_order" => "0",
      "legend_enabled"   => "0", "legend" => { "location" => "nw" }
    }
  end

  let(:query_settings) do
    {
      "tagged_icon"       => "", "tagged_color" => "palette-1", "period" => "month",
      "report_group_by"   => ["priority", "author"],
      "report_sum_column" => [""]
    }
  end

  let!(:query) do
    FactoryBot.create(:easy_project_query,
                       visibility:     EasyQuery::VISIBILITY_PUBLIC, outputs: ['list', 'chart', 'report'],
                       chart_settings: chart_settings, settings: query_settings)
  end
  let!(:page_module) do
    FactoryBot.create(:easy_page_zone_module,
                       easy_pages_id:                  1,
                       easy_page_available_zones_id:   1,
                       easy_page_available_modules_id: 19,
                       settings:                       { 'set_filter' => '1', 'query_type' => '1', 'query_id' => query.id.to_s, 'row_limit' => '10' }
    )
  end

  scenario 'multiple outputs' do
    visit home_path
    wait_for_ajax
    expect(page).to have_css('.easy-query-listing-links')
    expect(page).to have_css('.easy_query_chart')
    expect(page).to have_css('.easy_query_chart .c3-axis-x .tick', count: 12)
    expect(page).to have_css('table.report')
    expect(page).to have_css('table.projects')
    expect(page.find('table.projects td.name')).to have_content(project.name)
    previous_period = page.find('.easy-query-listing-links .period').text
    page.execute_script("$('.easy-query-listing-links .prev').trigger('click');")
    wait_for_ajax
    expect(page).to have_css('.easy_query_chart .c3-axis-x .tick', count: 12)
    expect(page.find('table.projects td.name')).to have_content(project.name)
    expect(page.find('.easy-query-listing-links .period').text).not_to eq(previous_period)
    page.find('.easy-query-heading-controls .icon-calendar-year').click
    wait_for_ajax
    expect(page).to have_css('.easy-query-heading-controls .icon-calendar-year.active')
    expect(page).to have_css('.easy_query_chart .c3-axis-x .tick', count: 4)
    expect(page.find('table.projects td.name')).to have_content(project.name)
  end
end

