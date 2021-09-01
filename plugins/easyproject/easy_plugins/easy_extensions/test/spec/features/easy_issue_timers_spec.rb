require 'easy_extensions/spec_helper'

feature 'Easy issue timer', :js => true, :logged => :admin do
  let(:issue) { FactoryGirl.create(:issue) }
  let(:issue_timer) { FactoryGirl.create(:easy_issue_timer, :user => User.current, :issue => issue) }

  context 'is displayed on sidebar' do
    scenario 'on my page' do
      issue_timer
      visit '/my/page'
      expect(page).to have_css('#easy_issue_timers_list_trigger')
    end
  end

end
