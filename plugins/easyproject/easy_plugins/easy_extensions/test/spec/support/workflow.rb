RSpec.shared_context 'workflows_support' do
  let(:project) { FactoryBot.create(:project, members: [User.current, user], trackers: [tracker]) }
  let(:issue_status1) { FactoryBot.create(:issue_status) }
  let(:issue_status2) { FactoryBot.create(:issue_status) }
  let(:issue) { FactoryBot.create(:issue, project: project, tracker: tracker, status: issue_status1) }
  let(:tracker) { FactoryBot.create(:tracker) }
  let(:user) { FactoryBot.create(:user) }
end