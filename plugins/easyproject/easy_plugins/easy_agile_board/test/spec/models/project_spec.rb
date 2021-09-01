require 'easy_extensions/spec_helper'

describe Project, type: :model, logged: :admin do
  let(:project) { FactoryGirl.create(:project, enabled_module_names: ['issue_tracking', 'easy_agile_board']) }
  let(:issue) { FactoryGirl.create(:issue, project: project) }
  let(:easy_kanban_issue) { FactoryGirl.create(:easy_kanban_issue, issue: issue, project: project) }

  it 'destroys easy kanban issue after project deletion' do
    easy_kanban_issue
    expect{project.destroy}.to change(EasyKanbanIssue, :count).by(-1)
  end
end
