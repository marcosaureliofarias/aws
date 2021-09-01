require 'easy_extensions/spec_helper'

describe EasyKanbanIssuesController do
  let(:project) { FactoryGirl.create(:project, members: [User.current, user], trackers: [tracker], add_modules: %w[easy_kanban_board]) }
  let(:subproject) { FactoryGirl.create(:project, parent_id: project, members: [User.current, user], trackers: [tracker], add_modules: %w[easy_kanban_board]) }
  let(:tracker) { FactoryGirl.create(:tracker) }
  let(:user) { FactoryGirl.create(:user) }
  let(:issue) { FactoryGirl.create(:issue, project: project, tracker: tracker, status: status_new) }
  let(:status_new) { FactoryGirl.create(:issue_status) }
  let(:status_realization) { FactoryGirl.create(:issue_status) }
  let(:status_done) { FactoryGirl.create(:issue_status) }
  let(:kanban_issue1) { FactoryGirl.create(:easy_kanban_issue, issue: issue, project: project, phase: '1') }
  let(:kanban_issue2) { FactoryGirl.create(:easy_kanban_issue, issue: issue, project: subproject, phase: '1') }
  let!(:agile_easy_setting) do
    EasySetting.create(name: 'kanban_statuses', value:
    {
      'progress' => {
        '1' => {'name' => 'New', 'state_statuses' => [status_new.id.to_s], 'status_id' => status_new.id.to_s, 'return_to' => '__nobody__'},
        '2' => {'name' => 'Realization', 'state_statuses' => [status_realization.id.to_s], 'status_id' => status_realization.id.to_s, 'return_to' => '__nobody__'}
      },
      'done' => {'state_statuses' => [status_done.id.to_s], 'status_id' => status_done.id.to_s, 'return_to' => '__nobody__'}
    })
  end

  context 'with admin user', logged: :admin do
    describe 'PATCH update (json)' do
      it 'moves issue in all kanbans according to status' do
        kanban_issue1; kanban_issue2
        with_easy_settings(easy_agile_use_workflow_on_kanban: false) do
          patch :update, params: {easy_kanban_issue: {phase: '2'}, project_id: subproject, id: issue, format: :json}
          expect(kanban_issue1.reload.phase.to_i).to eq(2)
        end
      end
    end
  end

  context 'workflow', logged: true do
    before(:each) do
      project
      role = User.current.reload.roles.first
      role.add_permission! :edit_issues
      issue.reload
    end

    describe 'PATCH update (json)' do
      it 'uses workflow and does not change status' do
        with_easy_settings(easy_agile_use_workflow_on_kanban: true) do
          patch :update, params: {easy_kanban_issue: {phase: '2'}, project_id: project, id: issue, format: :json}
          expect(issue.reload.status_id).to eq(status_new.id)
        end
      end

      it 'skip workflow and changes status' do
        with_easy_settings(easy_agile_use_workflow_on_kanban: false) do
          patch :update, params: {easy_kanban_issue: {phase: '2'}, project_id: project, id: issue, format: :json}
          expect(issue.reload.status_id).to eq(status_realization.id)
        end
      end
    end
  end
end
