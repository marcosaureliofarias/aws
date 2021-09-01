require 'easy_extensions/spec_helper'

describe EasyExternalEmailsController, logged: :admin do
  render_views

  let(:issue) { FactoryBot.create(:issue, easy_email_to: 'test@test.com', easy_email_cc: 'emailcc1@test.com, emailcc2@test.com') }

  context 'send to external email' do

    it 'get preview_external_email' do
      get :preview_external_email, params: { id: issue.id, entity_type: 'Issue' }
      expect(response).to be_successful
      mail_template = assigns(:mail_template)
      expect(mail_template.mail_recepient).to eq(issue.easy_email_to)
      expect(mail_template.mail_cc).to eq(issue.easy_email_cc)
    end

    it 'restrict external users' do
      allow_any_instance_of(User).to receive(:internal_client?).and_return(false)
      allow_any_instance_of(User).to receive(:external_client?).and_return(true)
      get :preview_external_email, params: { id: issue.id, entity_type: 'Issue' }
      expect(response).to have_http_status(403)
    end

    context '#send_external_email' do
      let(:attachment) { FactoryBot.create(:attachment, file: fixture_file_upload('files/yoda-tux-256.png'), container: issue, filesize: 500000) }

      it 'valid' do
        post :send_external_email, params: { id: issue.id, entity_type: 'Issue' }
        expect(flash[:notice]).to be_present
      end

      it 'invalid' do
        attachment
        with_settings("attachment_max_size" => 1) do
          post :send_external_email, params: { id: issue.id, entity_type: 'Issue', ids: [attachment.id], mail_sender: 'sender@test.com', mail_recepient: 'recipient@test.com' }
          expect(flash[:error]).to include(I18n.t(:error_validates_max_size))
        end
      end
    end

  end

end
