require 'easy_extensions/spec_helper'

RSpec.feature 'Jasmine', logged: :admin, js: true, js_wait: :long do

  let(:project) {
    FactoryGirl.create(:project, number_of_members: 2, add_modules: ['easy_gantt', 'easy_gantt_resources'])
  }
  let!(:issues) {
    FactoryGirl.create_list(:issue, 3, project_id: project.id, estimated_hours: 8)
  }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) { example.run }
  end

  after(:each) { clear_history }

  def clear_history
    script= <<-EOF
      (function(){
        ysy.history.clear();
      })();
    EOF
    page.execute_script(script)
  end

  describe 'Project RM' do
    it 'should not fail' do
      visit easy_gantt_path(project, gantt_type: 'rm', jasmine: true)
      wait_for_ajax
      expect(page).to have_css('.jasmine-bar')
      result = page.evaluate_script('jasmineHelper.parseResult();')
      expect(result).to eq('success')
    end
    it 'pipelined should not fail' do
      visit easy_gantt_path(project, gantt_type: 'rm', jasmine: true, combine_by_pipeline: true)
      wait_for_ajax
      expect(page).to have_css('.jasmine-bar')
      result = page.evaluate_script('jasmineHelper.parseResult();')
      expect(result).to eq('success')
    end
    it 'should render RM' do
      visit easy_gantt_path(project, gantt_type: 'rm', jasmine: true, combine_by_pipeline: true)
      wait_for_ajax
      expect(page).to have_css('#easy_gantt.resource_management')
    end
  end

  describe 'Global RM' do
    it 'should not fail' do
      visit easy_gantt_resources_path(jasmine: ['easy_gantt_resources/global_rm'])
      wait_for_ajax
      expect(page).to have_css('.jasmine-bar')
      result = page.evaluate_script('jasmineHelper.parseResult();')
      expect(result).to eq('success')
    end
    it 'pipelined should not fail' do
      visit easy_gantt_resources_path(jasmine: ['easy_gantt_resources/global_rm'], combine_by_pipeline: true)
      wait_for_ajax
      expect(page).to have_css('.jasmine-bar')
      result = page.evaluate_script('jasmineHelper.parseResult();')
      expect(result).to eq('success')
    end
  end

  describe 'Balancer' do
    it 'should not fail' do
      visit easy_gantt_resources_path(jasmine: ['easy_gantt_resources/balancer_test'])
      wait_for_ajax
      expect(page).to have_css('.jasmine-bar')
      result = page.evaluate_script('jasmineHelper.parseResult();')
      expect(result).to eq('success')
    end
    it 'pipelined should not fail' do
      visit easy_gantt_resources_path(jasmine: ['easy_gantt_resources/balancer_test'], combine_by_pipeline: true)
      wait_for_ajax
      expect(page).to have_css('.jasmine-bar')
      result = page.evaluate_script('jasmineHelper.parseResult();')
      expect(result).to eq('success')
    end
  end

end
