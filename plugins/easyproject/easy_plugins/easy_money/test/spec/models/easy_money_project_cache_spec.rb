require 'easy_extensions/spec_helper'

feature 'recalculate project cache', logged: :admin do
  let!(:project) { FactoryGirl.create(:project, :enabled_module_names => ['easy_money'])}
  let!(:easy_money_expected_expenses) { FactoryGirl.create_list(:easy_money_expected_expense, 2, :spent_on => Date.today, :price2 => 1, :entity => project)}

  it 'execute' do
    expect(EasyRakeTaskEasyMoneyProjectCache.new.execute).to be true
  end
end
