RSpec.shared_context 'attachments_support' do
  let(:project) { FactoryBot.create(:project) }
  let!(:member) { FactoryBot.create(:member, project: project, user: User.current) }
  let!(:document) { FactoryBot.create(:document, project: project) }
  let!(:attachment) { FactoryBot.create(:attachment, author: User.current, file: fixture_file_upload('files/testfile.txt', 'text/plain')) }
  let(:attachment_without_container) { FactoryBot.create(:attachment, author: User.current, container: nil, file: fixture_file_upload('files/testfile.txt', 'text/plain')) }
  let(:issue) { FactoryBot.create(:issue, project: project) }
  let(:user) { FactoryBot.create(:user) }
end