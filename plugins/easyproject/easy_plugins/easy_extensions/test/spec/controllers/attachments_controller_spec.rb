require 'easy_extensions/spec_helper'

describe AttachmentsController, logged: :admin do
  include_context 'attachments_support'

  it 'increments downloads' do
    expect(attachment.downloads).to eq 0
    get :download, params: { id: attachment.id }
    expect(response).to be_successful
    expect(attachment.reload.downloads).to eq 1
  end

  context 'mail preview' do
    let(:plain_text_mail) { FactoryBot.create(:attachment, file: fixture_file_upload('files/preview_emails/plain.eml', 'message/rfc822')) }
    let(:html_mail) { FactoryBot.create(:attachment, file: fixture_file_upload('files/preview_emails/html.eml', 'message/rfc822')) }
    let(:msg_mail) { FactoryBot.create(:attachment, file: fixture_file_upload('files/preview_emails/msg.msg', 'application/vnd.ms-outlook')) }
    let(:msg_mail_czech) { FactoryBot.create(:attachment, file: fixture_file_upload('files/preview_emails/msg_czech.msg', 'application/vnd.ms-outlook')) }

    around(:each) do |ex|
      with_settings({'text_formatting' => "HTML"}) do
        ex.run
      end
    end

    it 'plain' do
      get :show, params: { id: plain_text_mail.id }
      expect(response).to be_successful
      expect(assigns(:content)).to include("<br />")
    end

    it 'html' do
      get :show, params: { id: html_mail.id }
      expect(response).to be_successful
      expect(assigns(:content)).to include("image")
      expect(assigns(:content)).to include("<p>")
    end

    it 'msg' do
      get :show, params: { id: msg_mail.id }
      expect(response).to be_successful
      expect(assigns(:content)).to include("image")
      expect(assigns(:content)).to include("<p>")
    end

    it 'msg encoding' do
      get :show, params: { id: msg_mail_czech.id }
      expect(response).to be_successful
      expect(assigns(:content)).to include("test háčků a čárek")
    end
  end

  it 'increments downloads version' do
    attachment.update(description: 'Update attachment to next version!')
    get :download, params: { id: attachment.versions.last.id, version: true }
    expect(response).to be_successful
    expect(attachment.reload.downloads).to eq 1
  end

  it 'revert to version' do
    attachment.update(description: 'Update attachment to next version!')
    post :revert_to_version, params: { id: attachment.id, version_num: 1 }
    expect(attachment.reload.version).to eq(1)
  end

  it 'revert to version without permissions', logged: true do
    attachment.update(description: 'Update attachment to next version!')
    post :revert_to_version, params: { id: attachment.id, version_num: 1 }
    expect(attachment.reload.version).to eq(2)
    expect(response).to be_forbidden
  end

  it 'donwload attachments or version not create new revision' do
    get :download, params: { id: attachment.id }
    expect(response).to be_successful
    expect(attachment.reload.versions.count).to eq 1

    attachment.update(description: 'Update attachment to next version!')

    3.times do |x|
      get :download, params: { id: attachment.versions.last.id, version: true }
      expect(response).to be_successful
      expect(attachment.reload.versions.count).to eq 2
    end

  end

  it 'sends notifications when attachments are added to document' do
    ActionMailer::Base.deliveries = []
    document

    with_user_pref('no_self_notified' => '0') do
      with_settings notified_events: ['document_added'] do
        with_deliveries do
          post :attach, :params => { :attachments => [{ file: fixture_file_upload('files/testfile.txt', 'text/plain') }], entity_type: 'Document', entity_id: document.id }
        end
        expect(ActionMailer::Base.deliveries.size).to eq(1)
      end
    end
  end

  context 'REST API' do
    let(:attachment) { attachment_without_container }
    
    it 'attach file' do
      expect {
        post :attach, params: { attach: { entity_type: 'Issue', entity_id: issue.id, attachments: [{ token: attachment.token }] }, format: 'json', key: User.current.api_key }
      }.to change(issue.reload.attachments, :count).by 1
    end

    it 'wtf in api' do
      post :attach, params: { attach: { entity_type: 'Wtf', entity_id: 666, attachments: [{ token: attachment.token }] }, format: 'json', key: User.current.api_key }
      expect(response.status).not_to eq(500)
    end

  end

  context 'Delete attachments' do

    context '#delete' do
      it 'should destroy attchment with container' do
        container = attachment.container
        expect { delete :destroy, params: { id: attachment } }.to change(Attachment, :count).by(-1)
          .and change(container.journals, :count).by(1)
      end

      it 'should destroy attchment' do
        expect { delete :destroy, params: { id: attachment } }.to change(Attachment, :count).by(-1)
      end
    end

    context '#bulk_destroy' do
      it 'should destroy attchment with container' do
        container = attachment.container
        ids = [attachment_without_container, attachment].map(&:id)
        expect { delete :bulk_destroy, params: { ids: ids } }.to change(Attachment, :count).by(-2)
          .and change(container.journals, :count).by(1)
      end
    end

    context 'permissions' do
      it 'user is not allowed to delete if attachment not deletable' do
        attachment_without_container.author = user
        attachment_without_container.save

        expect { delete :destroy, params: { id: attachment_without_container } }.not_to change(Attachment, :count)
        expect(response).to have_http_status(403)

        ids = [attachment_without_container, attachment].map(&:id)
        expect { delete :bulk_destroy, params: { ids: ids } }.not_to change(Attachment, :count)
        expect(response).to have_http_status(403)
      end
    end
  end

end
