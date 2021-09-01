require 'easy_extensions/spec_helper'

describe AttachmentsController, logged: :admin do

  context 'REST API' do
    let(:attachment) { FactoryBot.create(:attachment, container: nil, file: fixture_file_upload('files/testfile.txt', 'text/plain')) }
    let(:easy_money_expected_expense) { FactoryBot.create(:easy_money_expected_expense) }

    it 'attach file to easy money' do
      expect {
        post :attach, params: { attach: { entity_type: easy_money_expected_expense.class.name, entity_id: easy_money_expected_expense.id, attachments: [{ token: attachment.token }] }, format: 'json', key: User.current.api_key }
      }.to change(easy_money_expected_expense.reload.attachments, :count).by 1
    end
  end

end
