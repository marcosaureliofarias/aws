require 'easy_extensions/spec_helper'

describe Issue, type: :model, logged: :admin do
  let(:project) { FactoryGirl.create(:project, add_modules: %w(easy_kanban_board)) }
  let(:status_new) { FactoryGirl.create(:issue_status) }
  let(:issue) { FactoryGirl.create(:issue, project: project, status: status_new) }
  let!(:agile_easy_setting) do
    EasySetting.create(name: 'kanban_statuses',
                       value: {
                         'progress' => {
                           '1' => {'name' => 'New', 'state_statuses' => [status_new.id.to_s], 'status_id' => status_new.id.to_s, 'return_to' => '__nobody__' }
                       } },
                       project_id: project.id)
  end

  it 'creating Issue creates EasyKanbanIssue' do
    project
    with_easy_settings(add_new_issues_to_project_kanban: true) do
      expect{issue}.to change(EasyKanbanIssue, :count).by(1)
      expect(issue.easy_kanban_issues.first.phase).to eq(1)
    end
  end
end
