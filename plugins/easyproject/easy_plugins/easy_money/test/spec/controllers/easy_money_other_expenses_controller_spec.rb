require 'easy_extensions/spec_helper'

describe EasyMoneyOtherExpensesController, logged: :admin do
  subject { FactoryBot.create(:easy_money_other_expense) }

  describe 'bulk edit' do
    it 'works with entities from allowed project' do
      expect_any_instance_of(User).to receive(:allowed_to?).with({ controller: 'easy_money_other_expenses', action: 'bulk_edit' }, [subject.project], global: true).and_return(true)
      get :bulk_edit, params: { ids: [subject.id] }
      expect(response).to have_http_status :success
    end

    it 'does not work with entities from restricted project' do
      expect_any_instance_of(User).to receive(:allowed_to?).with({ controller: 'easy_money_other_expenses', action: 'bulk_edit' }, [subject.project], global: true).and_return(false)
      get :bulk_edit, params: { ids: [subject.id] }
      expect(response).to have_http_status :forbidden
    end
  end

end
