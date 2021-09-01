require 'easy_extensions/spec_helper'

describe Document, logged: :admin do
  describe '#recipients_with_easy_extensions' do
    let(:user) { FactoryGirl.create(:user) }
    let(:email) { FactoryGirl.create(:email_address, :user => user) }
    let(:member) { FactoryGirl.create(:member, :user => user) }
    let!(:member_role) { FactoryGirl.create(:member_role, :member => member) }
    let!(:another_member_role) { FactoryGirl.create(:member_role, :member => member) }
    let(:document) { FactoryGirl.create(:document, :project => member.project) }

    it 'returns list of uniq emails' do
      member.project.reload
      recipients = document.recipients

      expect(recipients).to eq(recipients.uniq)
    end
  end
end
