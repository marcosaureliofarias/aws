require 'easy_extensions/spec_helper'

feature 'requirements integration', js: true, logged: :admin, skip: !Redmine::Plugin.installed?(:redmine_re) do
  let(:project) { FactoryBot.create(:project, add_modules: ['requirements']) }

  scenario 'project setup' do
    visit requirements_project_path(project)
    wait_for_ajax
    page.find('#detail_view .form-actions input[type="submit"]').click
    wait_for_ajax
    expect(page).to have_css('.jstree-node', text: project.name)
  end
end
