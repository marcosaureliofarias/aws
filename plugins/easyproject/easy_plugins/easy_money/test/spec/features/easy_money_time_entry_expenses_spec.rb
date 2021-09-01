require 'easy_extensions/spec_helper'

feature 'Easy money time entry expenses', :logged => :admin, :js => true do

  let(:project) { FactoryGirl.create(:project, :enabled_module_names => ['issue_tracking', 'time_tracking', 'easy_money']) }
  let(:issue) { FactoryGirl.create(:issue, :child_issue, :project => project) }
  let(:time_entry1) { FactoryGirl.create(:time_entry, :issue => issue) }
  let(:time_entry2) { FactoryGirl.create(:time_entry, :issue => issue.parent) }
  let(:easy_money_rate_type1) { FactoryGirl.create(:easy_money_rate_type) }
  let(:easy_money_rate_type2) { FactoryGirl.create(:easy_money_rate_type, :external) }
  let(:easy_money_time_entry_expense1) { FactoryGirl.create(:easy_money_time_entry_expense, :rate_type => easy_money_rate_type1, :time_entry => time_entry1) }
  let(:easy_money_time_entry_expense2) { FactoryGirl.create(:easy_money_time_entry_expense, :rate_type => easy_money_rate_type1, :time_entry => time_entry2) }
  let(:time_entry_expenses_path) { "/projects/#{project.id}/easy_money_time_entry_expenses" }
  let(:money_other_settings_path) { "/projects/#{project.id}/easy_money_settings/project_settings?tab=EasyMoneyOtherSettings" }

  def submit_settings
    page.find('.show-save-dialog-modal').click
    wait_for_ajax
    page.find('.ui-dialog-buttonset button').click
  end

  scenario 'internal external rate' do
    time_entry1; time_entry2; easy_money_rate_type1; easy_money_rate_type2
    visit money_other_settings_path
    page.find("#settings_rate_type option[value='all']").select_option
    submit_settings
    expect(page.find("#settings_rate_type option[value='all']")).to be_selected
    visit time_entry_expenses_path
    expect(page.first('.easy-money-issue-time-entry-expenses-container thead')).to have_content(Regexp.new(I18n.t(:internal, :scope => :easy_money_rate_type), 'i'))
    expect(page.first('.easy-money-issue-time-entry-expenses-container thead')).to have_content(Regexp.new(I18n.t(:external, :scope => :easy_money_rate_type), 'i'))
    visit money_other_settings_path
    page.find("#settings_rate_type option[value='internal']").select_option
    submit_settings
    expect(page.find("#settings_rate_type option[value='internal']")).to be_selected
    visit time_entry_expenses_path
    expect(page.first('.easy-money-issue-time-entry-expenses-container thead')).to have_content(Regexp.new(I18n.t(:internal, :scope => :easy_money_rate_type), 'i'))
    expect(page.first('.easy-money-issue-time-entry-expenses-container thead')).not_to have_content(Regexp.new(I18n.t(:external, :scope => :easy_money_rate_type), 'i'))
  end

  scenario 'checkbox include childs' do
    easy_money_rate_type1
    visit money_other_settings_path
    element = page.find('input#settings_include_childs')
    scroll_to(element)
    element.set(true)
    submit_settings
    expect(page.find('input#settings_include_childs')).to be_checked
    page.find('input#settings_include_childs').set(false)
    submit_settings
    expect(page.find('input#settings_include_childs')).not_to be_checked
  end

  scenario 'sum' do
    easy_money_time_entry_expense1; easy_money_time_entry_expense2;
    visit money_other_settings_path
    page.find("#settings_rate_type option[value='all']").select_option
    submit_settings
    visit time_entry_expenses_path
    expect(page.find(".issue-#{issue.id}")).to have_content(easy_money_time_entry_expense1.price.to_i.to_s)
    expect(page.find(".issue-#{issue.parent.id}")).to have_content(easy_money_time_entry_expense2.price.to_i.to_s)
    expect(page.find('.easy-money-issue-time-entry-expenses-container tfoot')).to have_content((easy_money_time_entry_expense1.price + easy_money_time_entry_expense2.price).to_i.to_s)
  end

  scenario 'details' do
    time_entry1; time_entry2;
    visit time_entry_expenses_path
    issue_selector = ".issue-#{issue.id}"
    expect(page).to have_css(issue_selector)
    magnifier = page.find("#{issue_selector} .easy-query-additional-ending-buttons > a.icon-magnifier")
    expect(page).not_to have_css("#entry-#{issue.id}")
    magnifier.click
    details = page.find("#entry-#{issue.id}")
    expect(details).to have_text(issue.project.name)
  end

end
