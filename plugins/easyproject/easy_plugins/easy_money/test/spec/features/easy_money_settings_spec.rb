require 'easy_extensions/spec_helper'

feature 'easy money settings', :logged => :admin, :js => true do

  let!(:role) { FactoryGirl.create(:role) }
  let!(:rate_type) { FactoryGirl.create(:easy_money_rate_type) }

  scenario 'save role rates' do
    visit '/easy_money_settings?tab=EasyMoneyRateRole'

    expect(page).to have_css('.entity-item-rate-type')
    page.first('.entity-item-rate-type > input').set(5)
    page.find('.save-dialog-submit')
    expect(page.first('.entity-item-rate-type > input').value).to include '5'
  end

end
