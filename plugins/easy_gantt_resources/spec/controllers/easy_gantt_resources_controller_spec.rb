require 'easy_extensions/spec_helper'

RSpec.describe EasyGanttResourcesController, logged: :admin do

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) { example.run }
  end

  context 'rest api' do
    let(:project) { FactoryGirl.create(:project, add_modules: ['easy_gantt', 'easy_gantt_resources']) }

    it 'disabled' do
      with_settings(rest_api_enabled: 0) do
        get :index, params: { project_id: project }
        expect(response).to be_server_error

        get :index
        expect(response).to be_server_error
      end
    end

    # Project RM does not exist, its gantt with RM mode
    it 'enabled' do
      get :index
      expect(response).to be_successful
    end
  end

  context 'API' do
    render_views

    let(:project) { FactoryGirl.create(:project, number_of_members: 2, add_modules: ['easy_gantt', 'easy_gantt_resources']) }
    let(:issues) do
      project.reload
      FactoryGirl.create_list(:issue, 5, project: project, estimated_hours: 20, assigned_to: project.users.first)
    end

    it 'project show' do
      issues.map(&:reload)
      issue_ids = issues.map(&:id)

      get :project_data, params: { project_id: project.id, project_ids: [project.id], issue_ids: issue_ids, resources_start_date: '', resources_end_date: '', format: 'json' }

      expect(response).to be_successful

      issues_data = json[:easy_resource_data]['issues']
      issues.each do |issue|
        issue_data = issues_data.find{|i| i['id'] == issue.id}
        expect(issue_data).to_not be_nil

        resources_data = Hash[issue_data['resources'].map{|date, alloc| [date.to_date, alloc['hours']]}]
        issue.easy_gantt_resources.each do |resource|
          expect(resource.hours.to_f).to eq(resources_data[resource.date].to_f)
        end
      end
    end

    it 'allocated issues' do
      get :allocated_issues, params: { format: 'json' }
      expect(response).to be_successful
    end

  end
end
