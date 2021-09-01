require 'easy_extensions/spec_helper'

feature 'Users query view', :js => true, :logged => :admin do
  let!(:admin_user) { FactoryGirl.create(:admin_user) }
  let!(:user) { FactoryGirl.create(:user) }

  scenario 'group by admin' do
    visit users_path(:set_filter => '1', :group_by => ['admin'], :load_groups_opened => '1')
    wait_for_ajax
    no_group  = page.find('tr[data-group-name=\'["0"]\']')
    yes_group = page.find('tr[data-group-name=\'["1"]\']')

    expect(no_group.find('.group-name')).to have_content(I18n.t(:general_text_No))
    expect(yes_group.find('.group-name')).to have_content(I18n.t(:general_text_Yes))

    no_group_entity_count  = no_group['data-entity-count'].to_i
    yes_group_entity_count = yes_group['data-entity-count'].to_i

    expect(page).to have_css("#entity-#{admin_user.id}")
    expect(page).to have_css("#entity-#{user.id}")

    user_index      = page.evaluate_script("$('#entity-#{user.id}').index()").to_i
    admin_index     = page.evaluate_script("$('#entity-#{admin_user.id}').index()").to_i
    no_group_index  = page.evaluate_script("$('##{no_group[:id]}').index()").to_i
    yes_group_index = page.evaluate_script("$('##{yes_group[:id]}').index()").to_i

    expect(user_index).to be > no_group_index
    expect(admin_index).to be > yes_group_index

    visible_entity_count = page.evaluate_script("$('tr[id^=entity-]').length").to_i
    expect(visible_entity_count).to eq(no_group_entity_count + yes_group_entity_count)
  end
end
