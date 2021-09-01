RSpec.shared_context 'easy_do_not_allow_close_if_subtasks_opened' do
  let(:project) { FactoryBot.create(:project) }
  let(:tracker) { FactoryBot.create(:tracker, easy_do_not_allow_close_if_subtasks_opened: true) }
  let(:issue) { FactoryBot.create(:issue, project: project, tracker: tracker) }
  let(:child_issue) { FactoryBot.create(:issue, parent: parent_issue, project: project, tracker: tracker) }
  let(:parent_issue) { FactoryBot.create(:issue, tracker: tracker, project: project) }
  let(:closed_status) { FactoryBot.create(:issue_status, is_closed: true) }
end
