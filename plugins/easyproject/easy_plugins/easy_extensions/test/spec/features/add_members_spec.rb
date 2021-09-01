require 'easy_extensions/spec_helper'

feature 'add members to project', js: true, logged: :admin do

  let(:project) { FactoryGirl.create(:project) }
  let(:default_role) { FactoryGirl.create(:role) }
  let(:easy_user_type) { FactoryGirl.create(:easy_user_type, default_role: default_role) }
  let!(:first_user_with_default_role) { FactoryGirl.create(:user, easy_user_type: easy_user_type) }
  let!(:second_user_with_default_role) { FactoryGirl.create(:user, easy_user_type: easy_user_type) }

  before(:each) do
    allow_any_instance_of(MembersController).to receive(:per_page_option).and_return(User.active.visible.not_member_of(project).count - 1)
  end

  scenario 'modal' do
    visit projects_settings_project_path(project, tab: :members)
    first('#sidebar_inner a.icon.icon-add.button-positive').click
    wait_for_ajax

    test_visibility_of_default_role
  end

  scenario 'html' do
    visit new_project_membership_path(project_id: project)

    test_visibility_of_default_role
  end

  def test_visibility_of_default_role
    expect(page).to have_css("li[data-user-id='#{first_user_with_default_role.id}'] .default-role", text: default_role.to_s)

    # select a role
    first("input#membership_role_id_#{default_role.id}").click
    expect(page).to have_css("li[data-user-id='#{first_user_with_default_role.id}'] .default-role.hidden", visible: :hidden)

    # go to the second page
    first('span.pagination a:last-of-type').click
    expect(page).to have_css("li[data-user-id='#{second_user_with_default_role.id}'] .default-role.hidden", visible: :hidden)

    # deselect selected role
    first("input#membership_role_id_#{default_role.id}").click
    expect(page).to have_css("li[data-user-id='#{second_user_with_default_role.id}'] .default-role", text: default_role.to_s)
  end
end
