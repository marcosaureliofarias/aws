require 'easy_extensions/spec_helper'

RSpec.describe EasyQueriesConcerns::Calculations, logged: :admin do

  def create_project(est1, est2)
    project        = FactoryBot.create(:project, number_of_issues: 2,
                                       number_of_issue_categories: 0,
                                       number_of_subprojects:      0)
    issue1, issue2 = project.issues
    issue1.update_attribute(:estimated_hours, est1)
    issue2.update_attribute(:estimated_hours, est1)
    project
  end

  context 'Regular query' do

    # Query should be always fresh because of caching
    def issue_query
      query              = EasyIssueQuery.new
      query.column_names = ['estimated_hours']
      query.group_by     = ['project']
      query
    end

    it 'entities_calculation' do
      project1 = create_project(50, 100)
      project2 = create_project(60, 0)
      project3 = create_project(500, 1000)

      issues            = issue_query.entities
      issues_by_project = issues.group_by(&:project_id)

      # Total sum
      estimated_hours = issues.sum(&:estimated_hours)
      expect(issue_query.entity_sum(:estimated_hours)).to eq(estimated_hours)
      expect(issue_query.entities_sum(:estimated_hours)).to eq(estimated_hours)

      # Total average
      average_estimated_hours = issues.sum(&:estimated_hours) / issues.size
      expect(issue_query.entities_average(:estimated_hours)).to be_within(0.1).of(average_estimated_hours)

      # Sums by project
      estimated_hours_by_projects  = issues_by_project.transform_values { |issues| issues.sum(&:estimated_hours) }
      entity_sum_estimated_hours   = issue_query.entity_sum(:estimated_hours, group: ['project_id'])
      entities_sum_estimated_hours = issue_query.entities_sum(:estimated_hours, group: ['project_id'])

      expect(entity_sum_estimated_hours).to eq(estimated_hours_by_projects)
      expect(entities_sum_estimated_hours).to eq(estimated_hours_by_projects)

      # Averages by project
      average_estimated_hours_by_projects = issues_by_project.transform_values { |issues| issues.sum(&:estimated_hours) / issues.size }
      entities_average_estimated_hours    = issue_query.entities_average(:estimated_hours, group: ['project_id'])

      expect(entities_average_estimated_hours).to eq(average_estimated_hours_by_projects)
    end

  end

  context 'With sumable_options[custom_sql]' do

    let(:change_value_by) { 3 }

    def issue_query
      query              = EasyIssueQuery.new
      query.column_names = ['estimated_hours']
      query.group_by     = ['project']

      estimated_hours_column                                      = query.available_columns.find { |c| c.name == :estimated_hours }
      estimated_hours_column.sumable_options.custom_sql[:sum]     = Arel.sql("SUM(estimated_hours) * #{change_value_by}")
      estimated_hours_column.sumable_options.custom_sql[:average] = Arel.sql("AVG(estimated_hours) / #{change_value_by}")

      query
    end

    it 'entities_calculation' do
      project1 = create_project(50, 100)
      project2 = create_project(60, 0)
      project3 = create_project(500, 1000)

      issues            = issue_query.entities
      issues_by_project = issues.group_by(&:project_id)

      # Total sum
      estimated_hours = issues.sum(&:estimated_hours) * change_value_by
      expect(issue_query.entities_sum(:estimated_hours)).to eq(estimated_hours)

      # Total average
      average_estimated_hours = (issues.sum(&:estimated_hours) / issues.size) / change_value_by
      expect(issue_query.entities_average(:estimated_hours)).to be_within(0.1).of(average_estimated_hours)

      # Sums by project
      estimated_hours_by_projects  = issues_by_project.transform_values { |issues| issues.sum(&:estimated_hours) * change_value_by }
      entities_sum_estimated_hours = issue_query.entities_sum(:estimated_hours, group: ['project_id'])
      expect(entities_sum_estimated_hours).to eq(estimated_hours_by_projects)

      # Averages by project
      average_estimated_hours_by_projects = issues_by_project.transform_values { |issues|
        (issues.sum(&:estimated_hours) / issues.size / change_value_by).round(2)
      }
      entities_average_estimated_hours    = issue_query.entities_average(:estimated_hours, group: ['project_id']).transform_values { |v| v.round(2) }
      expect(entities_average_estimated_hours).to eq(average_estimated_hours_by_projects)
    end

  end

  context 'With distinct columns' do

    def create_project
      project = super rand(100), rand(100)

      issue1, issue2 = project.issues

      # I need more records to ensure distinct is working
      FactoryBot.create_list(:time_entry, 2, hours: rand(99) + 1, issue: issue1, user: User.current)
      FactoryBot.create_list(:time_entry, 2, hours: rand(99) + 1, issue: issue2, user: User.current)

      project
    end

    def time_entry_query
      query              = EasyTimeEntryQuery.new
      query.column_names = ['hours', 'estimated_hours']
      query.group_by     = ['project']
      query
    end

    it 'entities_calculation' do
      project1 = create_project
      project2 = create_project

      time_entries            = time_entry_query.entities
      time_entries_by_project = time_entries.group_by(&:project_id)
      issues                  = Issue.where(id: time_entries.map(&:issue_id))

      # Hours sum (not distinct column)
      hours = time_entries.sum(&:hours)
      expect(time_entry_query.entities_sum(:hours)).to eq(hours)

      # Estimated hours sum (distinct column)
      estimated_hours = issues.map(&:estimated_hours).sum
      expect(time_entry_query.entities_sum(:estimated_hours)).to eq(estimated_hours)
    end

  end

end
