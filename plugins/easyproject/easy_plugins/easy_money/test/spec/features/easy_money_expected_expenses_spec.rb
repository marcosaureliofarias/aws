require 'easy_extensions/spec_helper'

feature 'Easy money expected expenses', logged: :admin, js: true do

  let(:easy_money_expected_expense) { FactoryGirl.create(:easy_money_expected_expense) }

  context 'with some valid expenses' do

    let!(:easy_money_expected_expenses) { FactoryGirl.create_list(:easy_money_expected_expense, 2)}

    scenario 'user checks the sum and it should be in right currency' do
      currency = EasyMoneySettings.find_by_name('currency')
      currency ||= EasyMoneySettings.new(:name => 'currency')
      currency.value = 'fufnik'
      currency.save

      visit easy_money_expected_expenses_path(:set_filter => '1', :show_sum_row => '1')

      txt = find('#totalsum-summary .price1').text
      expect(txt).to include('fufnik')
    end
  end
  
  context 'repeating' do
    let(:easy_money_other_expense_repeating) {
      FactoryGirl.create(:easy_money_other_expense, easy_is_repeating: true,
      easy_repeat_settings: Hash[ 'period' => 'daily', 'daily_option' => 'each', 'daily_each_x' => '1', 'endtype' => 'endless', 'create_now' => 'none' ])
    }
    
    scenario 'form' do
      visit edit_easy_money_other_expense_path(easy_money_other_expense_repeating)
      wait_for_ajax
      page.find('#edit_easy_money_repeat_options a').click
      wait_for_ajax
      expect(page).to have_css('#ajax-modal_easy_acts_as_easy_is_easy_repeating')
    end
  end

  scenario 'move to planned', js: true do
    easy_money_expected_expense
    visit easy_money_expected_expenses_path

    page.find('.entities td.name').right_click
    wait_for_ajax
    page.find('#context-menu a.icon-move').click
    wait_for_ajax

    page.find('#easy_entity_attribute_map_submit_button').click
    expect(page.find('.easy-query-heading').text).to include(I18n.t(:label_easy_money_other_expenses))
  end

end
