require 'easy_extensions/spec_helper'

feature 'users profile', :js => true, :logged => :admin do
  let(:user) { FactoryGirl.create(:user) }

  context 'edit' do
    scenario 'lesser admin' do
      visit edit_user_path(user)
      lesser_checkbox              = page.find('#user_easy_lesser_admin')
      lesser_permissions_container = '#easy_lesser_admin_permissions_container'
      expect(lesser_checkbox).not_to be_checked
      expect(page).not_to have_css(lesser_permissions_container)
      lesser_checkbox.set(true)
      expect(page).to have_css(lesser_permissions_container)
    end
  end
end
