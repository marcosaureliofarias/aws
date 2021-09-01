require "easy_extensions/spec_helper"
RSpec.describe EasyJournalMailer, type: :mailer, logged: :admin do

  let(:user) { FactoryBot.create(:user) }
  let(:notes) { "User @#{User.current.login} made a bad merge request. @#{user.login} reverted it" }
  let(:issue) { FactoryBot.create(:issue) }
  let(:journal) { FactoryBot.create(:journal, journalized: issue, user: User.current, notes: notes) }

  it '.deliver_mentioned' do
    journal
    expect {
      perform_enqueued_jobs do
        described_class.deliver_mentioned([User.current, user], journal)
      end
    }.to change { ActionMailer::Base.deliveries.size }.by(2)
  end

  it '.body with mention' do
    expect(described_class.user_mentioned(User.current, journal).body.encoded).to include(User.current.login)
  end
end