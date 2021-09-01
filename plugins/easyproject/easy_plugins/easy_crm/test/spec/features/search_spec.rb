require_relative '../spec_helper'

feature 'search for easy crm cases', :logged => :admin, :js => true, :js_wait => :long do
  let!(:project) { FactoryGirl.create(:project, :enabled_module_names => ['issue_tracking', 'easy_crm']) }
  let!(:easy_crm_case) { FactoryGirl.create(:easy_crm_case, :project => project) }

  scenario 'doesnt exist' do
    q = 'xxxxxxxx'
    visit(search_path({:q => q, :scope_type => 'all', :all_words => '1', :easy_crm_cases => '1', :easy_crm_case => {:all => 1}}))
    expect(page).to have_css('#search-results')
    expect(page.find('#search-results')).not_to have_content(easy_crm_case.name)
  end

  scenario 'exists' do
    q = easy_crm_case.name
    visit(search_path({:q => q, :scope_type => 'all', :all_words => '1', :easy_crm_cases => '1', :easy_crm_case => {:all => 1}}))
    expect(page).to have_css('#search-results')
    expect(page.find('#search-results')).to have_content(easy_crm_case.name)
  end

  scenario 'on a project' do
    q = easy_crm_case.name
    visit(search_path({:q => q, :scope => project.id.to_s, :scope_type => 'project', :all_words => '1', :easy_crm_cases => '1', :easy_crm_case => {:all => 1}}))
    expect(page).to have_css('#search-types #easy_crm_cases')
    expect(page).to have_css('#search-results')
    expect(page.find('#search-results')).to have_content(easy_crm_case.name)
  end
end
