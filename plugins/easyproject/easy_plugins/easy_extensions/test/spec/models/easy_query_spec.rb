require 'easy_extensions/spec_helper'

RSpec.describe(EasyQuery, type: :model) do

  context 'with stubbed entities', deletion: true do
    include EasyQueryHelpers

    let(:custom_field) { EasyQueryHelpers::StubEntityCustomField.create(name: 'custom_field', field_format: 'int', is_filter: true) }
    let(:list_values) { (1..3).map { |i| "Value #{i}" } }
    let(:multiple_custom_field) {
      EasyQueryHelpers::StubEntityCustomField.create(
          name:            'multiple_custom_field',
          field_format:    'list',
          multiple:        true,
          possible_values: list_values.join("\n")
      )
    }
    let(:entities) { FactoryGirl.create_list(:stub_entity, 10) }
    let(:query) { EasyQueryHelpers::EasyStubEntityQuery.new }

    before :each do
      create_stub_query_entity
      entities;
    end

    after :context do
      drop_stub_query_entity
    end

    describe '#personalized_field_value_for_statement' do
      it 'current project' do
        allow(query).to receive(:project).and_return(spy('Project', id: 1))
        expect(query.personalized_field_value_for_statement('xproject_id', ['current'])).to eq(['1'])
      end

      it 'current project as a single value' do
        allow(query).to receive(:project).and_return(spy('Project', id: 1))
        expect(query.personalized_field_value_for_statement('xproject_id', 'current')).to eq('1')
      end

      it 'current and another project' do
        allow(query).to receive(:project).and_return(spy('Project', id: 1))
        expect(query.personalized_field_value_for_statement('xproject_id', ['current', '2'])).to match_array(['1', '2'])
      end
    end

    describe '#groups' do
      context 'basic columns' do
        it 'give 4 groups' do
          query.group_by = 'name'
          groups         = query.groups
          expect(groups.keys.count).to eq(4)
        end

        it 'sums a summable columns' do
          query.group_by = 'name'
          query.groups.each do |group, attrs|
            group_scope = EasyQueryHelpers::StubEntity.where(name: group)
            expect(attrs[:count]).to eq(group_scope.count)
            expect(attrs[:sums][:bottom].values.first).to eq(group_scope.sum(:value))
          end
        end
      end

      context 'parent columns' do
        it 'sums a parent column' do
          query.group_by     = 'name'
          query.column_names = ['parent_value']
          query.groups.each do |group, attrs|
            group_scope = EasyQueryHelpers::StubEntity.where(name: group)
            expect(attrs[:sums][:bottom].values.first).to eq(group_scope.joins(:stub_parent).sum('stub_parents.value'))
          end
        end
      end

      context 'with custom field' do
        before :each do
          custom_field
          entities.each do |e|
            e.reload.custom_field_values = { custom_field.id.to_s => Random.rand(10) }
            e.save
          end
        end

        it 'sums a custom field' do
          query.column_names = ["cf_#{custom_field.id}"]
          query.group_by     = 'name'
          query.groups.each do |group, attrs|
            value = EasyQueryHelpers::StubEntity.where(name: group).to_a.sum { |e| e.custom_field_values.detect { |v| v.custom_field_id == custom_field.id }.value.to_i }
            expect(attrs[:sums][:bottom].values.first).to eq(value)
          end
        end
      end

      context 'with multiple list cf' do
        before :each do
          multiple_custom_field
          entities.each do |e|
            next unless Random.rand(5) > 0
            e.reload.custom_field_values = { multiple_custom_field.id.to_s => list_values.sample(Random.rand(2) + 1) }
            e.save
          end
        end

        it 'groups by multiple list cf and get right entities' do
          query.group_by = "cf_#{multiple_custom_field.id}"
          group_scope    = EasyQueryHelpers::StubEntity.joins(multiple_custom_field.format.join_for_order_statement(multiple_custom_field, false))
          query.groups.each do |group, attrs|
            scope    = group_scope.where(Arel::Table.new("cf_#{multiple_custom_field.id}")[:value].eq(group.presence))
            entities = scope.to_a
            expect(attrs[:count]).to eq(entities.size)
            expect(query.entities_for_group(group).collect { |e| e.id }).to match_array(entities.collect { |e| e.id })
          end
        end

        it 'groups by two attributes and get right entities' do
          query.group_by = ['value', "cf_#{multiple_custom_field.id}"]
          group_scope    = EasyQueryHelpers::StubEntity.joins(multiple_custom_field.format.join_for_order_statement(multiple_custom_field, false))
          #TODO test if all available combinations are present
          query.groups.each do |group, attrs|
            scope = group_scope.where(value: group[0].to_i).where(Arel::Table.new("cf_#{multiple_custom_field.id}")[:value].eq(group[1].presence))
            expect(attrs[:count]).to eq(scope.count)
            expect(attrs[:sums][:bottom].values.first).to eq(scope.sum(:value))
            expect(query.entities_for_group(group).collect { |e| e.id }).to match_array(scope.collect { |e| e.id })
          end
        end
      end
    end

    describe '#switch_period_zoom_to' do

      it 'behaves deterministically' do
        query.period_start_date = Date.today - 6.months
        query.period_end_date   = Date.today + 6.months
        expect(query.period_zoom).to eq('month')
        query.switch_period_zoom_to('year')
        expect(query.period_start_date).to be <= Date.today
        expect(query.period_end_date).to be >= Date.today
        query.switch_period_zoom_to('month')
        year = (Date.today - 6.months).beginning_of_year
        expect(query.period_start_date.to_date).to be_between(year - 1.day, year + 1.day)
      end

    end


    describe '#number_of_periods_by_zoom' do
      it 'gives right period numbers' do
        query.period_zoom = 'day'
        expect(query.number_of_periods_by_zoom).to eq(31)
        query.period_zoom = 'week'
        expect(query.number_of_periods_by_zoom).to eq(14)
        query.period_zoom = 'month'
        expect(query.number_of_periods_by_zoom).to eq(12)
        query.period_zoom = 'quarter'
        expect(query.number_of_periods_by_zoom).to eq(4)
        query.period_zoom = 'year'
        expect(query.number_of_periods_by_zoom).to eq(4)
      end
    end

    describe '#period_start_date' do
      it 'returns fiscal year if not set' do
        beg = Date.new(Date.today.year, 1, 5)
        with_easy_settings(fiscal_month: beg.month, fiscal_day: beg.day) do
          expect(query.period_start_date).to eq(beg.beginning_of_month)
        end
        query.period_start_date = Date.today
        expect(query.period_start_date).to eq(Date.today)
      end
    end

    describe '#period_end_date' do
      it 'returns fiscal year plus period if not set' do
        query.period_zoom = 'month'
        beg               = Date.new(Date.today.year, 1, 5)
        with_easy_settings(fiscal_month: beg.month, fiscal_day: beg.day) do
          expect(query.period_end_date).to eq((beg + 11.months).end_of_month)
        end
        query.period_end_date = Date.today
        expect(query.period_end_date).to eq(Date.today)
      end
    end

    describe 'add short filter' do
      it 'date' do
        expect { query.add_short_filter('date', '20160505') }.to change(query.filters, :count).by(1)
      end

      it 'wrong date' do
        expect { query.add_short_filter('date', '') }.to change(query.filters, :count).by(0)
      end
    end

    it '#visible_by_entities' do
      result = query.visible_by_entities
      expect(result[:visibility_title].is_a?(Symbol)).to be true
      expect(result[:visible_entities].is_a?(Array)).to be true
    end

  end

  describe 'filter by date custom field', logged: :admin do
    let(:easy_issue_query) { FactoryGirl.build_stubbed(:easy_issue_query) }
    let(:issue_custom_field) { FactoryGirl.create(:issue_custom_field, field_format: 'date', is_filter: true, max_length: 30) }
    let(:project) { FactoryGirl.create(:project, trackers: [tracker]) }
    let(:tracker) { FactoryGirl.create(:tracker, issue_custom_fields: [issue_custom_field]) }
    let(:issue1) { FactoryGirl.create(:issue, project: project, tracker: tracker, custom_field_values: {
        issue_custom_field.id => '2018-07-13'
    }) }
    let(:issue2) { FactoryGirl.create(:issue, project: project, tracker: tracker, custom_field_values: {
        issue_custom_field.id => '2018-07-12'
    }) }
    let(:issue3) { FactoryGirl.create(:issue, project: project, tracker: tracker, custom_field_values: {
        issue_custom_field.id => '2018-07-11'
    }) }

    it 'correct from & to' do
      issue1; issue2; issue3
      easy_issue_query.add_filter("cf_#{issue_custom_field.id}", 'date_period_2', { 'from' => '2018-07-12', 'to' => '2018-07-12' })
      expect(easy_issue_query.entities_ids).to eq([issue2.id])
    end
  end

  describe 'filter by datetime field', logged: :admin do
    let(:easy_issue_query) { FactoryBot.build_stubbed(:easy_issue_query) }
    let(:issue) { FactoryBot.create(:issue) }

    before(:each) do
      with_time_travel(0, now: Time.new(2020, 1, 1, 8)) do
        issue
      end
    end

    context 'without time zone' do
      it 'same date' do
        easy_issue_query.add_filter("created_on", 'date_period_2', { 'from' => '2020-01-01', 'to' => '2020-01-01' })
        expect(easy_issue_query.entities_ids).to eq([issue.id])
      end

      it 'different date' do
        easy_issue_query.add_filter("created_on", 'date_period_2', { 'from' => '2020-01-02', 'to' => '2020-01-02' })
        expect(easy_issue_query.entities_ids).to eq([])
      end
    end

    context 'in a different time zone' do
      it 'same date' do
        with_user_pref(time_zone: 'Hawaii') do # -10:00
          easy_issue_query.add_filter("created_on", 'date_period_2', { 'from' => '2020-01-01', 'to' => '2020-01-01' })
          expect(easy_issue_query.entities_ids).to eq([])
        end
      end

      it 'shifted date' do
        with_user_pref(time_zone: 'Hawaii') do # -10:00
          easy_issue_query.add_filter("created_on", 'date_period_2', { 'from' => '2019-12-31', 'to' => '2019-12-31' })
          expect(easy_issue_query.entities_ids).to eq([issue.id])
        end
      end
    end
  end

  describe 'filter by datetime custom field', logged: :admin do
    let(:easy_issue_query) { FactoryGirl.build_stubbed(:easy_issue_query) }
    let(:issue_custom_field) { FactoryGirl.create(:issue_custom_field, field_format: 'datetime', is_filter: true, max_length: 30) }
    let(:project) { FactoryGirl.create(:project, trackers: [tracker]) }
    let(:tracker) { FactoryGirl.create(:tracker, issue_custom_fields: [issue_custom_field]) }
    let(:issue1) { FactoryGirl.create(:issue, project: project, tracker: tracker, custom_field_values: {
        issue_custom_field.id => {
            date:   '2018-07-13',
            hour:   '0',
            minute: '15'
        }
    }) }
    let(:issue2) { FactoryGirl.create(:issue, project: project, tracker: tracker, custom_field_values: {
        issue_custom_field.id => {
            date:   '2018-07-12',
            hour:   '23',
            minute: '45'
        }
    }) }

    it 'in different time zones' do
      with_user_pref(time_zone: 'Tokyo') do # +09:00
        issue1; issue2 # instantiate in new time zone to save custom field in that zone
        easy_issue_query.add_filter("cf_#{issue_custom_field.id}", 'date_period_2', { 'from' => '2018-07-13', 'to' => '2018-07-13' })
        expect(easy_issue_query.entities_ids).to eq([issue1.id])
      end

      User.current.instance_variable_set(:@time_zone, nil)
      with_user_pref(time_zone: 'Beijing') do # +08:00
        expect(easy_issue_query.entities_ids).to eq([])
      end
    end

  end

  it 'sort_criteria_to_sql_order' do
    q    = EasyIssueQuery.new
    sort = q.sort_criteria_to_sql_order([['priority', 'desc'], ['subject', 'asc']])
    expect(/.*enumerations.*,.*subject.*/.match?(sort)).not_to be_nil
    expect(sort.split(',').count).to eq(2)
    sort = q.sort_criteria_to_sql_order([['subject', 'asc'], ['priority', 'desc']])
    expect(/.*subject.*,.*enumerations.*/.match?(sort)).not_to be_nil
    expect(sort.split(',').count).to eq(2)
    sort = q.sort_criteria_to_sql_order([['description', 'asc'], ['subject', 'asc']])
    expect(sort).to include('subject')
    expect(sort).not_to include('description')
  end

  context 'cf joins', logged: :admin do
    let(:easy_issue_query) { FactoryGirl.build_stubbed(:easy_issue_query) }
    let(:easy_project_query) { FactoryGirl.build_stubbed(:easy_project_query) }
    let(:issue_custom_field) { FactoryGirl.create(:issue_custom_field, field_format: 'string', is_filter: false) }
    let(:project_custom_field) { FactoryGirl.create(:project_custom_field, field_format: 'string', is_filter: false) }
    let(:project) { FactoryGirl.create(:project) }
    let(:tracker) { FactoryGirl.create(:tracker, issue_custom_fields: [issue_custom_field]) }
    let(:issue) { FactoryGirl.create(:issue, tracker: tracker) }
    let(:issue2) { FactoryGirl.create(:issue, tracker: tracker) }

    it 'issues' do
      cf                        = issue_custom_field
      issue.custom_field_values = { cf.id.to_s => 'test' }
      issue.save
      issue2
      cf_col_name                   = "cf_#{cf.id}".to_sym
      easy_issue_query.column_names = [cf_col_name]
      easy_issue_query.group_by     = cf_col_name
      easy_issue_query.set_sort_params('sort' => "cf_#{cf.id}")
      expect(easy_issue_query.groups.count).to eq(2)
      expect(easy_issue_query.entities_for_group('').count).to eq(1)
      expect(easy_issue_query.entities_for_group('test').count).to eq(1)
    end

    it 'projects' do
      cf                          = project_custom_field
      project.custom_field_values = { cf.id.to_s => 'test' }
      project.save
      cf_col_name                     = "cf_#{cf.id}".to_sym
      easy_project_query.column_names = [cf_col_name]
      easy_project_query.group_by     = cf_col_name
      easy_project_query.set_sort_params('sort' => "cf_#{cf.id}")
      expect(easy_project_query.groups.count).to eq(1)
      expect(easy_project_query.entities_for_group('').count).to eq(0)
      expect(easy_project_query.entities_for_group('test').count).to eq(1)
    end
  end

  context 'entity sum', :logged => :admin do
    let(:issue1) { FactoryGirl.create(:issue, :estimated_hours => 7.2) }
    let(:issue2) { FactoryGirl.create(:issue, :estimated_hours => 7.2) }
    let(:time_entry1) { FactoryGirl.create(:time_entry, :hours => 5, :issue => issue1) }
    let(:time_entry2) { FactoryGirl.create(:time_entry, :hours => 5, :issue => issue2) }
    let(:time_entries) { [time_entry1, time_entry2] }
    let(:easy_time_entry_query) { FactoryGirl.build(:easy_time_entry_query) }
    let(:int_custom_field) { FactoryGirl.create(:time_entry_custom_field, :field_format => 'int') }
    let(:float_custom_field) { FactoryGirl.create(:time_entry_custom_field, :field_format => 'float') }

    it 'sum cf int' do
      cf = int_custom_field
      time_entries.each do |t|
        t.custom_field_values = { cf.id.to_s => 3 }
        t.save
      end
      cf_col_name                        = "cf_#{cf.id}".to_sym
      easy_time_entry_query.column_names = [cf_col_name]
      expect(easy_time_entry_query.entity_sum(cf_col_name)).to eq(6)
    end

    it 'sum cf float' do
      cf = float_custom_field
      time_entries.each do |t|
        t.custom_field_values = { cf.id.to_s => 3.3 }
        t.save
      end
      cf_col_name                        = "cf_#{cf.id}".to_sym
      easy_time_entry_query.column_names = [cf_col_name]
      expect(easy_time_entry_query.entity_sum(cf_col_name)).to eq(6.6)
    end

    it 'sum estimated hours on time entries (distinct columns)' do
      time_entries
      easy_time_entry_query.column_names = [:estimated_hours]
      expect(easy_time_entry_query.entity_sum(:estimated_hours)).to eq(14.4)
    end

    it 'sum estimated hours on time entries - no records (distinct columns)' do
      easy_time_entry_query.column_names = [:estimated_hours]
      expect(easy_time_entry_query.entity_sum(:estimated_hours)).to eq(0.0)
    end

    it 'sum hours - no records' do
      easy_time_entry_query.column_names = [:hours]
      expect(easy_time_entry_query.entity_sum(:hours)).to eq(0.0)
    end

    it 'sum hours' do
      time_entries
      easy_time_entry_query.column_names = [:hours]
      expect(easy_time_entry_query.entity_sum(:hours)).to eq(10.0)
    end
  end

  context 'invoicing', :logged => :admin do
    let(:easy_invoice_proforma1) { FactoryGirl.create(:easy_invoice_proforma) }
    let(:easy_invoice_proforma_query) { FactoryGirl.build(:easy_invoice_proforma_query) }

    it 'works with STI entity and distinct column' do
      easy_invoice_proforma1
      easy_invoice_proforma_query.column_names = [:total]
      expect(easy_invoice_proforma_query.entity_sum(:total)).to eq(0.0)
    end
  end if Redmine::Plugin.installed?(:easy_invoicing)

  context 'easy project query', logged: :admin do

    let!(:project1) { FactoryBot.create(:project, enabled_module_names: ['issue_tracking']) }
    let!(:project2) { FactoryBot.create(:project, enabled_module_names: %w[issue_tracking time_tracking]) }
    let!(:project3) { FactoryBot.create(:project, enabled_module_names: %w[news documents]) }
    let(:easy_project_query) { FactoryBot.build(:easy_project_query) }

    it 'has_module_filter' do
      easy_project_query.add_filter('has_enabled_modules', '=', ['issue_tracking'])
      expect(easy_project_query.entities).to contain_exactly(project1, project2)
      easy_project_query.add_filter('has_enabled_modules', '=', %w[issue_tracking time_tracking])
      expect(easy_project_query.entities).to contain_exactly(project2)
      easy_project_query.add_filter('has_enabled_modules', '!', %w[issue_tracking time_tracking])
      expect(easy_project_query.entities).to contain_exactly(project3)
    end
  end

end
