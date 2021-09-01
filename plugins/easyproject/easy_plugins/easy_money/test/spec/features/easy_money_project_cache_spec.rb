require 'easy_extensions/spec_helper'

feature 'Easy money project cache', :logged => :admin, :js => true do

  let(:project) { FactoryGirl.create(:project, :enabled_module_names => ['easy_money'], :members => [User.current])}
  let(:project_with_custom_value) { FactoryGirl.create(:project, :enabled_module_names => ['easy_money'], :members => [User.current])}
  let(:project_custom_field) { FactoryGirl.create(:project_custom_field, :field_format => 'string', :is_for_all => true, :show_on_list => true) }

  scenario 'group by associated custom fields' do
    cf = project_custom_field
    project
    cf_project = project_with_custom_value
    cf_project_cache = EasyMoneyProjectCache.create!(:project_id => cf_project.id)
    project_cache = EasyMoneyProjectCache.create!(:project_id => project.id)
    cf_project.custom_field_values = { cf.id.to_s => 'test' }
    cf_project.save!
    cf_project_cache_css = ".entities tr#entity-#{cf_project_cache.id}"
    project_cache_css = ".entities tr#entity-#{project_cache.id}"

    visit easy_money_project_caches_path(:set_filter => '1', :group_by => "cf_#{cf.id}", :load_groups_opened => '1')
    wait_for_ajax
    expect(page).to have_css(cf_project_cache_css)
    expect(page).to have_css(project_cache_css)
    expect(page).to have_css(".entities tr.group", :count => 2)

    position_diff = page.evaluate_script("$('#{cf_project_cache_css}').index()").to_i - page.evaluate_script("$('#{project_cache_css}').index()").to_i
    expect(position_diff.abs).to be > 1
  end

  scenario 'tiles output' do
    project_cache = EasyMoneyProjectCache.create!(:project_id => project.id)
    visit easy_money_project_caches_path(:set_filter => '1', :outputs => ['tiles'])
    expect(page).to have_css('.easy-entity-card')
  end
end
