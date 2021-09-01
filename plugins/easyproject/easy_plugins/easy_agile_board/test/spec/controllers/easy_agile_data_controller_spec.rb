require 'easy_extensions/spec_helper'

describe EasyAgileDataController, logged: :admin do

  context 'GET swimlane_values' do
    let(:sprint_with_issues) { FactoryBot.create(:easy_sprint, issues: FactoryBot.create_list(:issue, 1)) }
    let!(:project) { FactoryBot.create(:project) }
    let!(:user) { FactoryBot.create(:user) }
    let!(:group) { FactoryBot.create(:group) }
    let!(:priority1) { FactoryBot.create(:issue_priority) }
    let!(:priority2) { FactoryBot.create(:issue_priority) }
    let!(:priority3) { FactoryBot.create(:issue_priority) }
    let!(:tracker1) { FactoryBot.create(:tracker, projects: [project]) }
    let!(:tracker2) { FactoryBot.create(:tracker, projects: [project]) }
    let!(:milestone1) { FactoryBot.create(:version, project_id: project.id, due_date: Date.today + 5, status: 'open') }
    let!(:milestone2) { FactoryBot.create(:version, project_id: project.id, due_date: Date.today - 5, status: 'closed') }
    let!(:issue1) { FactoryBot.create(:issue, project: project) }
    let!(:issue2) { FactoryBot.create(:issue, project: project, parent_id: issue1.id) }
    let!(:fields) { %w(assigned_to_id priority_id tracker_id author_id fixed_version_id parent_id) }
    let!(:operators) { {
      assigned_to_id: '=',
      priority_id: '=',
      tracker_id: '!',
      author_id: '!*',
      fixed_version_id: 'c',
      parent_id: '!'
    } }
    let!(:values) { {
      assigned_to_id: [group.id.to_s],
      priority_id: [priority2.id.to_s, priority3.id.to_s],
      tracker_id: [tracker1.id.to_s],
      parent_id: [issue1.id.to_s]
    } }

    it 'fetches swimlane values for all swimlanes' do
      AgileHelperMethods.swimlane_names.each do |swimlane|
        get :swimlane_values, params: {set_filter: 1, type: 'EasyAgileBoardQuery', output: 'scrum', easy_sprint_id: sprint_with_issues.id.to_s, only_path: true, filter_name: swimlane, format: :json}

        expect(response).to be_successful
      end
    end

    context 'filtered by query' do
      it 'fetches swimlane values for swimlane' do
        AgileHelperMethods.swimlane_names.each do |swimlane|
          with_settings(issue_group_assignment: '1') do
            get :swimlane_values, params: {set_filter: 1, type: 'EasyIssueQuery', fields: fields, operators: operators, values: values, output: 'kanban', only_path: true, filter_name: swimlane, format: :json}

            response_json = JSON.parse(response.body)
            case swimlane
            when 'assigned_to_id'
              expect(response_json.size).to eq(1)
              expect(response_json.first[1]).to eq(group.id.to_s)
            when 'priority_id'
              response_ids = response_json.map{|value_array| value_array[1].to_s }
              expect(response_json.size).to eq(2)
              expect(response_ids).to include(priority2.id.to_s, priority3.id.to_s)
            when 'tracker_id'
              response_ids = response_json.map{|value_array| value_array[1].to_s }
              expect(response_ids).not_to include(tracker1.id.to_s)
              expect(response_ids).to include(tracker2.id.to_s)
            when 'author_id'
              expect(response_json.size).to eq(0)
            when 'fixed_version_id'
              response_ids = response_json.map{|value_array| value_array[1].to_s }
              expect(response_ids).not_to include(milestone1.id.to_s)
              expect(response_ids).to include(milestone2.id.to_s)
            when 'parent_id'
              expect(response_json.size).to eq(0)
            else # 'none'
              expect(response).to be_successful
            end
          end
        end
      end
    end
  end

end
