require_relative '../spec_helper'

feature 'Easy Crm Charts' do
  let!(:user){ FactoryGirl.create(:admin_user) }
  let!(:project) { FactoryGirl.create(:project, :enabled_module_names => ['issue_tracking', 'easy_crm'],) }
  before(:each) do
    logged_user(user)
    I18n.locale = :en

  end

  # scenario 'add to my page', js: true do
  #   # visit '/my/page_layout'
  #   visit "/projects/#{project.id}/easy_crm/layout"
  #   # within '#list-top' do
  #   #   select I18n.t(:'easy_pages.modules.easy_calendar'), :from => "module_id"
  #   # end
  #   # visit '/'
  #   # page.should have_text(I18n.t(:'easy_pages.modules.easy_calendar'))

  # end
end
