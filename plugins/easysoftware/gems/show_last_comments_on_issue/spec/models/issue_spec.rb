RSpec.describe Issue, logged: :admin do

  let(:issue) { FactoryBot.create(:issue) }
  let(:comments) {FactoryBot.create_list(:last_comments_journal, 5, journalized: issue, notes: 'ahoj')}
  let(:nil_journals) {FactoryBot.create_list(:last_comments_journal, 2, journalized: issue, notes: nil)}
  let(:blank_journals) {FactoryBot.create_list(:last_comments_journal, 2, journalized: issue, notes: '')}

  it '#last ten comments' do
    comments
    nil_journals
    blank_journals
    expect(issue.last_comments.count).to eq(5)
  end

end
