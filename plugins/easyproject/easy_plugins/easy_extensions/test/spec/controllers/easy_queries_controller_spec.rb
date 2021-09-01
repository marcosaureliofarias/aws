require 'easy_extensions/spec_helper'

describe EasyQueriesController do

  let(:project) { FactoryBot.create(:project) }

  describe '#new', logged: :admin do

    it 'set query for all projects without project_id' do
      get :new, :params => { type: 'EasyIssueQuery' }
      expect(assigns(:easy_query).project).to be_nil
      expect(assigns(:easy_query)).to be_is_for_all
    end

    it 'set query for project with project_id' do
      get :new, :params => { type: 'EasyIssueQuery', project_id: project }
      expect(assigns(:easy_query).project).to eq(project)
      expect(assigns(:easy_query)).not_to be_is_for_all
    end

    it 'set right filters and group_by' do
      get :new, :params => { type: 'EasyIssueQuery', status_id: "o|7", author_id: "=|me", group_by: 'project' }
      expect(assigns(:easy_query).filters.keys).to include('status_id', 'author_id')
      expect(assigns(:easy_query).filters['status_id'][:operator]).to eq('o')
      expect(assigns(:easy_query).group_by).to eq(['project'])
    end

  end

  describe '#create', logged: :admin do
    it 'set query attributes from params' do
      post :create, :params => { type:       'EasyIssueQuery', easy_query: { name: 'TestName', visibility: EasyQuery::VISIBILITY_PRIVATE },
                                 project_id: project, status_id: "o|7", author_id: "=|me", group_by: 'author', confirm: '1' }
      expect(assigns(:easy_query)).not_to be_new_record
      expect(assigns(:easy_query)).not_to be_is_for_all
      expect(assigns(:easy_query).name).to eq('TestName')
      expect(assigns(:easy_query).project).to eq(project)
      expect(assigns(:easy_query).filters.keys).to include('status_id', 'author_id')
      expect(assigns(:easy_query).filters['status_id'][:operator]).to eq('o')
      expect(assigns(:easy_query).group_by).to eq(['author'])
    end

    it 'set multiple grouping for query from params' do
      post :create, :params => { type:       'EasyIssueQuery', easy_query: { name: 'TestName', visibility: EasyQuery::VISIBILITY_PRIVATE },
                                 project_id: project, group_by: ['author', 'assigned_to'], confirm: '1' }
      expect(assigns(:easy_query)).not_to be_new_record
      expect(assigns(:easy_query)).not_to be_is_for_all
      expect(assigns(:easy_query).name).to eq('TestName')
      expect(assigns(:easy_query).project).to eq(project)
      expect(assigns(:easy_query).group_by).to eq(['author', 'assigned_to'])
    end
  end

  describe '#update', logged: :admin do
    let(:easy_query) { FactoryBot.create(:easy_issue_query) }
    let(:easy_time_entry_query) {FactoryBot.create(:easy_time_entry_query)}

    it 'set query attributes' do
      patch :update, :params => { type:      'EasyIssueQuery', id: easy_query, easy_query: { name: 'TestName' },
                                  status_id: "o|7", author_id: "=|me", group_by: 'author', set_filter: '1' }
      easy_query.reload
      expect(easy_query.name(translated: false)).to eq('TestName')
      expect(easy_query.filters.keys).to include('status_id', 'author_id')
      expect(easy_query.group_by).to eq(['author'])
    end

    it 'set time entries query attributes' do
      patch :update, params: { type: 'EasyTimeEntryQuery', id: easy_time_entry_query, set_filter: 1,
                               easy_query: { name: 'Test name', is_tagged: 0},
                               query_is_for_all: 1,
                               chart_settings: {primary_renderer: 'bar',
                                                axis_x_column: 'spent_on',
                                                axis_y_type: 'sum',
                                                axis_y_column: 'hours',
                                                cumulative: '0',
                                                y_label: '',
                                                secondary_axis_y_column: '',
                                                bar_direction: 'vertical',
                                                bar_limit: '0',
                                                long_tail: '0',
                                                bar_reverse_order: '0',
                                                bar_sort_by_axis_x: '0',
                                                legend_enabled: '0',
                                                legend: {location: 'nw'}},
                               period_zoom: 'day',
                               outputs: ['list', 'chart'],
                               fields: ['spent_on'],
                               operators: {spent_on: 'date_period_2'},
                               values: {spent_on: {period: 'current_week',
                                                   period_days2: '',
                                                   period_days: '',
                                                   from: '2020-04-29',
                                                   to: '2020-05-10',
                                                   shift:''}}}
      easy_time_entry_query.reload
      expect(easy_time_entry_query.name(translated: false)).to eq('Test name')
      expect(easy_time_entry_query.period_start_date).to eq(Date.new(2020, 4, 29))
      expect(easy_time_entry_query.period_end_date).to eq(Date.new(2020, 5, 10))
    end
  end

  describe '#chart', logged: :admin do
    render_views

    def chart_values
      json[:data]['json'].collect { |d| d['values'].to_f }
    end

    def chart_groups
      json[:data]['json'].collect { |d| d['name'] }
    end

    let(:page_module) { FactoryBot.create :easy_page_zone_module, :with_chart_settings }
    let(:page_module_with_incorrect_settings) {
      pm                                             = FactoryGirl.create :easy_page_zone_module, :with_chart_settings
      pm.settings['chart_settings']['axis_y_column'] = 'non_existing_column'
      pm.save
      pm
    }
    let(:chart_request_params) {
      {
          "group_by"           => "",
          "load_groups_opened" => "1",
          "set_filter"         => "1",
          "show_avatars"       => "0",
          "show_sum_row"       => "0",
          "type"               => "EasyIssueQuery",
          "uuid"               => page_module.uuid,
          "easy_query_type"    => "EasyIssueQuery",
          "format"             => "json"
      }
    }

    it 'returns correct chart data' do
      FactoryGirl.create_list(:issue, 2, estimated_hours: rand(2..10))
      get :chart, :params => page_module.settings['chart_settings'].merge(chart_request_params)

      entities = EasyIssueQuery.new.entities
      projects = entities.map(&:project)

      estimated_hours_sum = entities.sum { |i| i.estimated_hours.to_i }
      expect(chart_values.sum).to eq(estimated_hours_sum)

      json[:data]['json'].each do |project_data|
        project = projects.find { |p| p.id == project_data['raw_name'] }
        expect(project.name).to eq(project_data['name'])
      end
    end

    it 'returns no data with incorrect chart settings' do
      FactoryBot.create_list :issue, 2

      chart_request_params['uuid'] = page_module_with_incorrect_settings.uuid

      get :chart, :params => page_module_with_incorrect_settings.settings['chart_settings'].merge(chart_request_params)
      estimated_hours_sum = 0
      expect(chart_values.sum).to eq(estimated_hours_sum)
    end

    it 'returns correct chart data grouped_by_date_column' do
      FactoryBot.create_list(:issue, 2, start_date: '2016-05-05', estimated_hours: rand(2..10))

      settings = {
          'period_start_date'       => '2016-01-01',
          'period_end_date'         => '2016-12-31',
          'period_zoom'             => 'month',
          'period_date_period_type' => '2',
          'set_filter'              => '1',
          'type'                    => 'EasyIssueQuery',
          'outputs'                 => ['chart'],
          'chart'                   => '1',
          'group_by'                => 'start_date',
          'format'                  => 'json',
          'chart_settings'          => {
              'primary_renderer'        => 'bar',
              'axis_x_column'           => 'start_date',
              'axis_y_type'             => 'sum',
              'axis_y_column'           => 'estimated_hours',
              'secondary_axis_y_column' => '',
              'bar_direction'           => 'vertical',
              'period_column'           => 'start_date',
              'bar_limit'               => '0',
              'legend_enabled'          => '0',
              'legend'                  => {
                  'location'  => 'nw',
                  'placement' => 'insideGrid'
              }
          }
      }

      get :chart, :params => settings
      expect(chart_values.sum).to eq(Issue.sum(:estimated_hours))

      json[:data]['json'].each do |issue_data|
        expect(issue_data).to have_key('raw_name')
        expect(issue_data['raw_name']).to include('|')

        from_to = issue_data['raw_name'].split('|')
        from_to.each do |value|
          formated_range = subject.format_period(Time.parse(value), :month)
          expect(formated_range).to eq(issue_data['name'])
        end
      end
    end

    it 'week period does not cause an inifinite loop' do
      FactoryGirl.create_list :issue, 2, :start_date => '2016-05-05'

      settings = {
          'period_start_date'       => '2016-01-01',
          'period_end_date'         => '2016-12-31',
          'period_zoom'             => 'week',
          'period_date_period_type' => '2',
          'set_filter'              => '1',
          'type'                    => 'EasyIssueQuery',
          'outputs'                 => ['chart'],
          'chart'                   => '1',
          'group_by'                => 'start_date',
          'format'                  => 'json',
          'chart_settings'          => {
              'primary_renderer'        => 'bar',
              'axis_x_column'           => 'start_date',
              'axis_y_type'             => 'sum',
              'axis_y_column'           => 'estimated_hours',
              'secondary_axis_y_column' => '',
              'bar_direction'           => 'vertical',
              'period_column'           => 'start_date',
              'bar_limit'               => '0',
              'legend_enabled'          => '0',
              'legend'                  => {
                  'location'  => 'nw',
                  'placement' => 'insideGrid'
              }
          }
      }

      get :chart, params: settings
      expect(chart_values.sum).to eq(Issue.sum(:estimated_hours))
    end

    it 'returns correct groups' do
      FactoryBot.create :issue, :start_date => '2016-05-05', :due_date => '2016-05-05', :estimated_hours => 1
      FactoryBot.create :issue, :start_date => '2016-05-05', :due_date => '2016-06-05', :estimated_hours => 2

      settings = {
          'period_start_date'       => '2016-01-01',
          'period_end_date'         => '2016-12-31',
          'period_zoom'             => 'month',
          'period_date_period_type' => '2',
          'set_filter'              => '1',
          'easy_query_type'         => 'EasyIssueQuery',
          'outputs'                 => ['chart'],
          'chart'                   => '1',
          'group_by'                => 'start_date',
          'format'                  => 'json',
          'chart_settings'          => {
              'primary_renderer'        => 'bar',
              'axis_x_column'           => 'start_date',
              'axis_y_type'             => 'sum',
              'axis_y_column'           => 'estimated_hours',
              'secondary_axis_y_column' => '',
              'bar_direction'           => 'vertical',
              'period_column'           => 'start_date',
              'bar_limit'               => '0',
              'legend_enabled'          => '0',
              'legend'                  => {
                  'location'  => 'nw',
                  'placement' => 'insideGrid'
              },
              'additional_queries'      => {
                  '0' => {
                      'set_filter'      => '1',
                      'easy_query_type' => 'EasyIssueQuery',
                      'outputs'         => ['chart'],
                      'chart'           => '1',
                      'group_by'        => 'due_date',
                      'format'          => 'json',
                      'chart_settings'  => {
                          'primary_renderer'        => 'bar',
                          'axis_x_column'           => 'due_date',
                          'axis_y_type'             => 'sum',
                          'axis_y_column'           => 'estimated_hours',
                          'secondary_axis_y_column' => '',
                          'bar_direction'           => 'vertical',
                          'period_column'           => 'due_date',
                          'bar_limit'               => '0',
                          'legend_enabled'          => '0',
                          'legend'                  => {
                              'location'  => 'nw',
                              'placement' => 'insideGrid'
                          }
                      }
                  }
              }
          }
      }

      get :chart, :params => settings
      expect(chart_groups.count).to eq(12)
    end

    it 'correct when chart settings cumulative enabled' do
      (1..11).step(2).map { |s| "%02d" % s }.each do |month|
        FactoryBot.create :issue, :start_date => '2016-01-01', :due_date => "2016-#{month}-01", :estimated_hours => 1
      end
      settings = {
          'period_start_date'       => '2016-01-01',
          'period_end_date'         => '2016-12-31',
          'period_zoom'             => 'month',
          'period_date_period_type' => '2',
          'set_filter'              => '1',
          'easy_query_type'         => 'EasyIssueQuery',
          'outputs'                 => ['chart'],
          'chart'                   => '1',
          'group_by'                => '',
          'format'                  => 'json',
          'chart_settings'          => {
              'primary_renderer'        => 'bar',
              'cumulative'              => '1',
              'axis_x_column'           => 'due_date',
              'axis_y_type'             => 'sum',
              'axis_y_column'           => 'estimated_hours',
              'secondary_axis_y_column' => 'estimated_hours',
              'bar_direction'           => 'vertical',
              'period_column'           => 'due_date',
              'bar_limit'               => '0',
              'legend_enabled'          => '0',
              'legend'                  => {
                  'location'  => 'nw',
                  'placement' => 'insideGrid'
              },
              'additional_queries'      => {
                  '0' => {
                      'set_filter'      => '1',
                      'easy_query_type' => 'EasyIssueQuery',
                      'outputs'         => ['chart'],
                      'chart'           => '1',
                      'group_by'        => '',
                      'format'          => 'json',
                      'chart_settings'  => {
                          'primary_renderer'        => 'bar',
                          'cumulative'              => '1',
                          'axis_x_column'           => 'due_date',
                          'axis_y_type'             => 'sum',
                          'axis_y_column'           => 'estimated_hours',
                          'secondary_axis_y_column' => '',
                          'bar_direction'           => 'vertical',
                          'period_column'           => 'due_date',
                          'bar_limit'               => '0',
                          'legend_enabled'          => '0',
                          'legend'                  => {
                              'location'  => 'nw',
                              'placement' => 'insideGrid'
                          }
                      }
                  }
              }
          }
      }
      get :chart, :params => settings
      expected_values = [1.0, 1.0, 2.0, 2.0, 3.0, 3.0, 4.0, 4.0, 5.0, 5.0, 6.0, 6.0]
      expect(json[:data]['json'].collect { |d| d['values'].to_f }).to eq expected_values
      expect(json[:data]['json'].collect { |d| d['values2'].to_f }).to eq expected_values
      expect(json[:data]['json'].collect { |d| d['additional_0'].to_f }).to eq expected_values
    end
  end

  describe 'save query', :logged => :admin do
    render_views

    let(:project) { FactoryBot.create(:project, :identifier => 'blabla') }

    it 'assigns project with alias' do
      get :new, :params => { :type => 'EasyIssueQuery', :project_id => project }
      expect(assigns(:project)).not_to be_nil
    end
  end

  describe 'show query', :logged => :admin do
    render_views

    let(:project) { FactoryBot.create(:project) }
    let(:project2) { FactoryBot.create(:project, :identifier => 'blabla') }
    let(:easy_issue_query) { FactoryBot.create(:easy_issue_query) }
    let(:easy_project_query) { FactoryBot.create(:easy_project_query) }
    let(:project_easy_issue_query) { FactoryBot.create(:easy_issue_query, :project => project) }
    let(:project_easy_issue_query2) { FactoryBot.create(:easy_issue_query, :project => project2) }

    it 'project query' do
      get :show, :params => { :id => easy_project_query.id }
      expect(response).to redirect_to(projects_path(:query_id => easy_project_query.id))
    end

    it 'issue query' do
      get :show, :params => { :id => easy_issue_query.id }
      expect(response).to redirect_to(issues_path(:query_id => easy_issue_query.id))
    end

    it 'project issue query' do
      get :show, :params => { :id => project_easy_issue_query.id }
      expect(response).to redirect_to(project_issues_path(project, :query_id => project_easy_issue_query.id))
    end

    it 'project issue query with identifier' do
      get :show, :params => { :id => project_easy_issue_query2.id }
      expect(response).to redirect_to(project_issues_path(project2, :query_id => project_easy_issue_query2.id))
    end
  end

  context 'load_users_for_copy', logged: true do
    let!(:easy_query) { FactoryBot.create(:easy_issue_query, visibility: EasyQuery::VISIBILITY_PUBLIC) }
    let!(:user2) { FactoryBot.create(:user) }

    it 'load users' do
      get :load_users_for_copy, params: { easy_query_id: easy_query.id, format: 'js' }, xhr: true
      expect(response).to be_successful
    end
  end

  context 'filter values', :logged => :admin do
    let(:issue) { FactoryBot.create(:issue) }
    let(:issue_status) { FactoryBot.create(:issue_status) }
    let(:issue_cf) { FactoryBot.create(:issue_custom_field, :possible_values => ['a', 'b'], :field_format => 'list', :is_for_all => true, :is_filter => true, :trackers => [issue.tracker]) }

    it 'status' do
      issue_status
      issue
      post :filter_values, :params => { :filter_name => "status_id", :set_filter => '1', :type => 'EasyIssueQuery', :fields => ["status_id"], :outputs => ['list'], :format => 'json' }
      expect(response).to be_successful
      expect(assigns(:values)).to include([issue_status.to_s, issue_status.id.to_s])
    end

    it 'cf list' do
      post :filter_values, :params => { :filter_name => "cf_#{issue_cf.id}", :set_filter => '1', :type => 'EasyIssueQuery', :fields => ["cf_#{issue_cf.id}"], :outputs => ['list'], :format => 'json' }
      expect(response).to be_successful
      expect(assigns(:values)).to match_array(['a', 'b'])
    end

    it 'render 404 if type is nil' do
      post :filter_values, params: { filter_name: "status_id",
                                     set_filter: '1',
                                     type: '',
                                     fields: ["status_id"],
                                     outputs: ['list'],
                                     format: 'json' }
      expect(response).to be_not_found
    end
  end

  context 'preview', logged: :admin do
    let(:issue) { FactoryBot.create(:issue) }

    it 'show entities' do
      issue
      post :preview, params: { easy_query_type: 'EasyIssueQuery', block_name: 'test', easy_query_render: 'table', 'test' => { data: 'x' } }
      expect(assigns(:entities)).to eq([issue])
    end
  end

end
