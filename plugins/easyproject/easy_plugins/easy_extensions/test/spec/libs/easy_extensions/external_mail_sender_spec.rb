require 'easy_extensions/spec_helper'

RSpec.describe EasyExtensions::ExternalMailSender do
  let(:entity) { double }
  let(:mail_template) { EasyExtensions::EasyMailTemplate.new }

  before do
    allow(entity).to receive(:save)
    allow(entity).to receive(:clear_current_journal)
    allow(entity).to receive(:current_journal).and_return(double)
  end

  describe 'call' do
    it 'should create entity journal' do
      # stub send_email, attach_email
      allow_any_instance_of(described_class).to receive(:send_email)
      allow_any_instance_of(described_class).to receive(:attach_email)
      allow_any_instance_of(described_class).to receive(:valid?).and_return(true)

      expect(entity).to receive(:init_journal).with(User.current, I18n.t(:text_external_email_sent, email: mail_template.mail_recepient))
      expect(entity.current_journal).to receive(:private_notes=).with(true)
      expect(entity).to receive(:save)

      described_class.call(entity, mail_template)
    end

    it 'send email' do
      sender = double('ExternalMailSender')
      email  = double
      allow(sender).to receive(:valid?).and_return(true)
      # should initialize
      expect(described_class).to receive(:new).and_return(sender)
      # should create journal
      expect(sender).to receive(:create_journal)
      # should send email
      expect(sender).to receive(:send_email).and_return(email)
      # should attach email
      expect(sender).to receive(:attach_email)

      described_class.call(entity, mail_template)
    end


    it 'should deliver mail' do
      mail = double
      allow_any_instance_of(described_class).to receive(:valid?).and_return(true)
      allow(mail).to receive(:deliver)

      expect(EasyExternalMailer).to receive(:easy_external_mail).with(mail_template, entity, nil, nil).and_return(mail)

      described_class.new(entity, mail_template).send_email
    end

    it 'should not include logo' do
      allow_any_instance_of(described_class).to receive(:valid?).and_return(true)
      with_settings(text_formatting: 'HTML') do
        mail_template.mail_body_html = '<p>template</p>'
        mail                         = described_class.new(Issue.new(updated_on: Date.today, created_on: Date.today), mail_template).send_email.to_s
        expect(mail).to include('template')
        expect(mail).not_to include('logo')
      end
    end

  end

end
