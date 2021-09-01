require "easy_extensions/spec_helper"
RSpec.describe EasyMailHandler do
  context 'all_mails_cc_array' do
    let(:email) { double }
    let(:handler) {
      handler = described_class.new
      handler.instance_variable_set(:@handler_options, {})
      handler
    }

    let(:issue) { double }

    before(:each) do
      described_class.send(:public, *described_class.protected_instance_methods)
      allow(email).to receive(:to) {}
      allow(email).to receive(:cc) { 'test@cc.test' }
      allow(issue).to receive(:easy_email_cc) { 'easy_email_cc@cc.test' }
      allow(issue).to receive(:easy_email_to) { 'customer@to.test' }
    end

    it 'easy_email_cc blank' do
      expect(handler.all_mails_cc_array(email)).to match_array(['test@cc.test'])
    end

    it 'email nil' do
      expect(handler.all_mails_cc_array(nil, issue)).to match_array(['easy_email_cc@cc.test'])
    end

    it 'concat easy_email_cc and cc from reply' do
      expect(handler.all_mails_cc_array(email, issue)).to match_array(['test@cc.test', 'easy_email_cc@cc.test'])
    end

    it 'uniq' do
      allow(issue).to receive(:easy_email_cc) { 'easy_email_cc@cc.test, test@cc.test' }
      expect(handler.all_mails_cc_array(email, issue)).to match_array(['test@cc.test', 'easy_email_cc@cc.test'])
    end

    it 'reject mailbox name' do
      handler.handler_options[:easy_helpdesk_mailbox_username] = 'mailbox@easy.test'
      allow(email).to receive(:cc) { ['test@cc.test', 'mailbox@easy.test'] }
      expect(handler.all_mails_cc_array(email, issue)).to match_array(['easy_email_cc@cc.test', 'test@cc.test'])
    end

    it 'reject easy_email_to' do
      allow(email).to receive(:cc) { ['test@cc.test', 'customer@to.test'] }
      expect(handler.all_mails_cc_array(email, issue)).to match_array(['easy_email_cc@cc.test', 'test@cc.test'])
    end

    it 'validate emails' do
      allow(email).to receive(:cc) { 'invalid@cctest' }
      allow(issue).to receive(:easy_email_cc) { 'invalid.test' }
      expect(handler.all_mails_cc_array(email, issue)).to match_array([])
    end
  end
end
