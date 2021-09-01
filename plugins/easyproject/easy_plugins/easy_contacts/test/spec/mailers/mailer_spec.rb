require "easy_extensions/spec_helper"
RSpec.describe Mailer, type: :mailer, logged: :admin do

  context 'easy contact journal link' do
    let(:contact) { FactoryBot.create(:easy_contact) }
    let(:contact_ref) { "easy_contact##{contact.id}" }
    let(:notes) { "Contact #{contact_ref}" }
    let(:issue) { FactoryBot.create(:issue) }
    let(:journal) { FactoryBot.create(:journal, journalized: issue, notes: notes) }

    it 'mail body' do
      body = described_class.issue_edit(User.current, journal).body.encoded
      expect(body).to include('Contact ')
      expect(body).to include(contact.to_s)
    end
  end
end