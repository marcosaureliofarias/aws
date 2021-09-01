require File.expand_path('../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)

RSpec.feature 'Correct tree', logged: :admin, js: true, js_wait: :long do
  let(:project) {
    FactoryGirl.create(:project, add_modules: ['easy_gantt'], number_of_issues: 0)
  }
  let(:sub_project) {
    sub_project = FactoryGirl.create(:project, parent_id: project.id, number_of_issues: 0)
    FactoryGirl.create(:issue, :project_id => sub_project.id, start_date: Date.today-1, due_date: Date.today + 1)
    sub_project
  }
  let(:project_issues) {
    Array.new(3) do |i|
      FactoryGirl.create(:issue, :project_id => project.id, start_date: Date.today-2+3*i, due_date: Date.today + 3*i)
    end
  }
  let(:milestone) {
    FactoryGirl.create(:version, project_id: project.id, due_date: Date.today + 5)
  }
  let(:milestone_issues) {
    Array.new(3) do |i|
      FactoryGirl.create(:issue, :project_id => project.id, :fixed_version_id => milestone.id, start_date: Date.today + i, due_date: Date.today + i + 1)
    end
  }
  let(:sub_issues) {
    Array.new(3) do |i|
      FactoryGirl.create(:issue, :project_id => project.id, :parent_issue_id => milestone_issues[0].id, start_date: Date.today + 2 - 2*i, due_date: Date.today + 3 - 2*i)
    end
  }
  let(:sub_sub_issues) {
    FactoryGirl.create_list(:issue, 3, :parent_issue_id => sub_issues[0].id, :project_id => project.id,start_date: Date.today + 2, due_date: Date.today + 2)
  }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) { example.run }
  end
  [true, false].each do |combine|
    it 'should show project items in correct order' do
      sub_sub_issues
      project_issues
      sub_project
      visit easy_gantt_path(project, combine_by_pipeline: combine)
      wait_for_ajax
      bars_area = page.find('.gantt_grid_data')
      # bars_area = page.find('.gantt_bars_area')
      order_list = [
        project,
        project_issues[0],
        project_issues[1],
        project_issues[2],
        milestone,
        milestone_issues[0],
        sub_issues[2],
        sub_issues[1],
        sub_issues[0],
        sub_sub_issues[0],
        sub_sub_issues[1],
        sub_sub_issues[2],
        milestone_issues[1],
        milestone_issues[2],
        sub_project
      ]
      prev_id = nil
      order_list.each do |issue|
        if issue.is_a? Project
          id = 'p' + issue.id.to_s
          name = issue.name
        elsif issue.is_a? Version
          id = 'm' + issue.id.to_s
          name = issue.name
        else
          id = issue.id
          name = issue.subject
        end
        expect(bars_area).to have_text(name)
        unless prev_id.nil?
          expect(bars_area.find("div[task_id='#{prev_id}']+div[task_id='#{id}']")).not_to be_nil
        end
        prev_id = id
      end
    end
  end
end