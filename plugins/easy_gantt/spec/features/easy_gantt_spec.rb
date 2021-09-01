require File.expand_path('../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)

RSpec.feature 'Easy gantt', js: true, logged: :admin do
  let!(:project) { FactoryGirl.create(:project, add_modules: ['easy_gantt']) }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) { example.run }
  end

  describe 'show gantt' do

    scenario 'show easy gantt on project' do
      visit easy_gantt_path(project)
      wait_for_ajax
      # unless Redmine::Plugin.installed?(:easy_gantt_pro)
      #   page.find('#sample_close_button').click
      #   wait_for_ajax
      # end
      expect(page).to have_css('#easy_gantt')
      expect(page.find('.gantt_grid_data')).to have_content(project.name)
      expect(page.find('#header')).to have_content(project.name)
    end

    context 'custom fields' do
      let(:issue_custom_field) { FactoryBot.create(:issue_custom_field, is_for_all: true, field_format: 'string', tracker_ids: Tracker.all.pluck(:id)) }
      let(:project_custom_field) { FactoryBot.create(:project_custom_field, is_for_all: true, field_format: 'string') }
      let(:issue) { project.issues.first }

      scenario 'left grid' do
        CustomValue.create(customized: issue, custom_field: issue_custom_field, value: 'issuecf')
        CustomValue.create(customized: project, custom_field: project_custom_field, value: 'projectcf')
        visit easy_gantt_path(project, {set_filter: '1', column_names: ['assigned_to', "cf_#{issue_custom_field.id}", "projects.cf_#{project_custom_field.id}"]})
        wait_for_ajax

        expect(page).to have_css('.gantt_grid_head_assigned_to', text: I18n.t(:field_assigned_to))
        expect(page).to have_css(".gantt_grid_head_cf_#{issue_custom_field.id}", text: issue_custom_field.name)
        expect(page).to have_css(".gantt_grid_head_projects_cf_#{project_custom_field.id}", text: project_custom_field.name)

        expect(page).to have_css('.gantt_grid_body_assigned_to', text: issue.assigned_to.name)
        expect(page).to have_css(".gantt_grid_body_cf_#{issue_custom_field.id}", text: 'issuecf')
        expect(page).to have_css(".gantt_grid_body_projects_cf_#{project_custom_field.id}", text: 'projectcf')
      end
    end

  end
end
