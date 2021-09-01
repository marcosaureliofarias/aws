require 'easy_extensions/spec_helper'

describe EasyMoneyController, logged: :admin do

  describe 'change_easy_money_type' do
    let(:attachment) { FactoryBot.create(:attachment, file: fixture_file_upload('files/testfile.txt', 'text/plain')) }
    let(:easy_money_expected_expense) { FactoryBot.create(:easy_money_expected_expense, attachments: [attachment])}

    it 'copy attachments' do
      EasyEntityAttributeMap.create(entity_from_type: 'EasyMoneyExpectedExpense', entity_to_type: 'EasyMoneyOtherExpense', entity_from_attribute: 'project', entity_to_attribute: 'project')
      EasyEntityAttributeMap.create(entity_from_type: 'EasyMoneyExpectedExpense', entity_to_type: 'EasyMoneyOtherExpense', entity_from_attribute: 'name', entity_to_attribute: 'name')
      easy_money_expected_expense
      expect {
        expect {
          post :change_easy_money_type, params: {easy_money_target_type: 'EasyMoneyOtherExpense', easy_money_type: 'EasyMoneyExpectedExpense', ids: [easy_money_expected_expense.id]}
        }.to change(EasyMoneyOtherExpense, :count).by(1)
      }.to change(Attachment, :count).by(1)
    end
  end

end
