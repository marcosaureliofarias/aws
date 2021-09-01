require File.expand_path('../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)

RSpec.feature 'Jasmine', logged: :admin, js: true, js_wait: :long do

  let(:subproject) {
    FactoryGirl.create(:project, parent_id: superproject.id, add_modules: ['easy_gantt'], number_of_issues: 3)
  }
  let(:superproject) {
    FactoryGirl.create(:project, add_modules: ['easy_gantt'], number_of_issues: 3)
  }
  let(:superproject_milestone_issues) {
    FactoryGirl.create_list(:issue, 3, fixed_version_id: superproject_milestone.id, project_id: superproject.id)
  }
  let(:subproject_milestone_issues) {
    FactoryGirl.create_list(:issue, 3, fixed_version_id: subproject_milestone.id, project_id: subproject.id)
  }
  let(:subproject_milestone) {
    FactoryGirl.create(:version, project_id: subproject.id)
  }
  let(:superproject_milestone) {
    FactoryGirl.create(:version, project_id: superproject.id)
  }
  let(:subissues) {
    FactoryGirl.create_list(:issue, 3, parent_issue_id: superproject.issues[0].id, project_id: superproject.id)
  }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) { example.run }
  end

  describe 'Project gantt' do
    it 'should not fail' do
      visit easy_gantt_path(superproject, jasmine: true)
      wait_for_ajax
      expect(page).to have_css('.jasmine-bar')
      result = page.evaluate_script('jasmineHelper.parseResult();')
      expect(result).to eq('success')
    end
    it 'pipelined should not fail' do
      visit easy_gantt_path(superproject, jasmine: true, combine_by_pipeline: true)
      wait_for_ajax
      expect(page).to have_css('.jasmine-bar')
      result = page.evaluate_script('jasmineHelper.parseResult();')
      expect(result).to eq('success')
    end
  end

  describe 'Global gantt' do
    it 'should not fail' do
      visit easy_gantt_path(jasmine: ['easy_gantt/global_gantt'])
      wait_for_ajax
      expect(page).to have_css('.jasmine-bar')
      result = page.evaluate_script('jasmineHelper.parseResult();')
      expect(result).to eq('success')
    end
    it 'pipelined should not fail' do
      visit easy_gantt_path(jasmine: ['easy_gantt/global_gantt'], combine_by_pipeline: true)
      wait_for_ajax
      expect(page).to have_css('.jasmine-bar')
      result = page.evaluate_script('jasmineHelper.parseResult();')
      expect(result).to eq('success')
    end
  end

end
