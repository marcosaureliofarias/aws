require 'easy_extensions/spec_helper'

describe EasyShortUrlsController, logged: :admin do
  let(:attachment_for_all) { FactoryBot.create(:attachment, :with_short_url_external) }
  let(:attachment_for_all_with_file) { FactoryBot.create(:attachment, :with_short_url_external, file: fixture_file_upload('files/testfile.txt', 'text/plain')) }

  context 'shortcut' do
    it 'readable' do
      expect(attachment_for_all_with_file.readable?).to eq(true)
      shortcut = EasyShortUrl.find_by(entity_type: 'Attachment', entity_id: attachment_for_all_with_file.id)
      get :shortcut, params: { shortcut: shortcut.shortcut }
      expect(response).to have_http_status(200)
    end

    it 'unreadable' do
      expect(attachment_for_all.readable?).to eq(false)
      shortcut = EasyShortUrl.find_by(entity_type: 'Attachment', entity_id: attachment_for_all.id)
      get :shortcut, params: { shortcut: shortcut.shortcut }
      expect(response).to have_http_status(404)
    end
  end

end
