require 'easy_extensions/spec_helper'

describe 'EasyIssueQuery', :logged => :admin do
  let(:project) { FactoryGirl.create(:project) }
  let(:project_two) { FactoryGirl.create(:project) }
  let(:custom_field) { FactoryGirl.create(:issue_custom_field, :projects => [project.id], :is_for_all => false, :visible => true) }
  let(:custom_field_two) { FactoryGirl.create(:issue_custom_field, :projects => [project_two.id], :is_for_all => false, :visible => true) }
  let(:custom_field_for_all) { FactoryGirl.create(:issue_custom_field, :visible => true) }

  describe '#available_columns' do
    before(:each) do
      custom_field; custom_field_two; custom_field_for_all
    end

    context 'when project specific query' do
      it 'contains only CFs for its project or for all projects' do
        query                      = EasyIssueQuery.new(:name => '_', :project => project)
        query_custom_field_columns = query.available_columns.select { |cf| cf.is_a?(EasyQueryCustomFieldColumn) }
        custom_field_two_detected  = query_custom_field_columns.detect { |col| col.custom_field == custom_field_two }

        expect(query_custom_field_columns.count).to eq(2)
        expect(custom_field_two_detected).to be_nil
      end
    end

    context 'when global query' do
      it 'contains only CFs for all projects' do
        query                      = EasyIssueQuery.new(:name => '_')
        query_custom_field_columns = query.available_columns.select { |cf| cf.is_a?(EasyQueryCustomFieldColumn) }

        expect(query_custom_field_columns.count).to eq(3)
      end
    end

    context 'is_private column' do
      it 'wont contain column without global setting' do
        with_easy_settings(enable_private_issues: false) do
          query         = EasyIssueQuery.new(:name => '_')
          query_columns = query.available_columns.select { |column| column.name == :is_private }

          expect(query_columns.count).to eq(0)
        end
      end

      it 'contains column with global setting' do
        with_easy_settings(enable_private_issues: true) do
          query         = EasyIssueQuery.new(:name => '_')
          query_columns = query.available_columns.select { |column| column.name == :is_private }

          expect(query_columns.count).to eq(1)
        end
      end
    end
  end

  describe '#additional_group_attributes' do
    context 'when group entity count is nil' do
      it 'returns zero percent' do
        project; project_two
        query      = EasyIssueQuery.new(:group_by => 'assigned_to')
        attributes = { :count => nil }
        query.additional_group_attributes(nil, attributes, nil)
        expect(attributes[:percent]).to eq(0)
      end
    end
  end

  describe 'scope testing' do
    let(:child_project) { FactoryGirl.create(:project, parent: project, number_of_issues: 0) }
    let(:issue) { FactoryGirl.create(:issue, project: child_project) }

    it 'tracker in order condition without group or column' do
      project; project_two
      q = EasyIssueQuery.new(name: 'My', column_names: [:subject, :project, :done_ratio, :due_date])
      expect(q.create_entity_scope(order: ['trackers']).count).to eq(2)
    end

    it 'group by parent project' do
      project; issue
      q          = EasyIssueQuery.new(name: 'My', column_names: [:subject, :project, :assigned_to, :status])
      q.group_by = ['parent_project']
      expect(q.entities_for_group(["#{project.id}"], {}).map(&:id)).to match_array(child_project.issues.map(&:id))
    end

  end

  context 'filters' do
    before(:each) do
      day = Time.parse('2017-09-15')
      with_time_travel(-1.day, :now => day) { issue1 }
      with_time_travel(0, :now => day) { issue2 }
      with_time_travel(1.day, :now => day) { issue3 }
    end

    context 'updated on' do
      let(:issue1) { FactoryGirl.create(:issue) }
      let(:issue2) { FactoryGirl.create(:issue) }
      let(:issue3) { FactoryGirl.create(:issue) }

      it 'date range >=' do
        q = EasyIssueQuery.new(name: 'My')
        q.from_params('set_filter' => '1', 'updated_on' => '>=2017-09-15')
        expect(q.filters).not_to be_blank
        expect(q.entities_ids.sort).to eq([issue2.id, issue3.id].sort)
      end

      it 'date range <=' do
        q = EasyIssueQuery.new(name: 'My')
        q.from_params('set_filter' => '1', 'updated_on' => '<=2017-09-15')
        expect(q.filters).not_to be_blank
        expect(q.entities_ids.sort).to eq([issue1.id, issue2.id].sort)
      end
    end

    context 'last updated on' do
      let(:issue1) { FactoryGirl.create(:issue, :with_journals) }
      let(:issue2) { FactoryGirl.create(:issue, :with_journals) }
      let(:issue3) { FactoryGirl.create(:issue, :with_journals) }

      it 'date range >=' do
        q = EasyIssueQuery.new(name: 'My')
        q.from_params('set_filter' => '1', 'last_updated_on' => '>=2017-09-15')
        expect(q.filters).not_to be_blank
        expect(q.entities_ids.sort).to eq([issue2.id, issue3.id].sort)
      end

      it 'date range <=' do
        q = EasyIssueQuery.new(name: 'My')
        q.from_params('set_filter' => '1', 'last_updated_on' => '<=2017-09-15')
        expect(q.filters).not_to be_blank
        expect(q.entities_ids.sort).to eq([issue1.id, issue2.id].sort)
      end
    end
  end

  context 'period setttings' do
    let!(:issue) { FactoryBot.create :issue, start_date: Date.today }
    let!(:issue_prev_year) { FactoryBot.create :issue, start_date: Date.today - 1.year }
    let(:query) { FactoryBot.build_stubbed :easy_issue_query, {
        period_start_date: '2016-01-01',
        period_end_date: '2016-12-31',
        period_zoom: 'month',
        period_date_period_type: '2'
      }
    }
    let(:query_settings) {
      {
        'start_date'              => 'current_month',
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
          }
        }
      }
    }

    it 'override from filter' do
      query.from_params(query_settings)
      expect(query.entity_count).to eq(1)
      expect(query.period_start_date.year).to eq(Date.today.year)
    end
  end
end
