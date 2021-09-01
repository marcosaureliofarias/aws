require 'easy_extensions/spec_helper'

feature 'dmsf integration', js: true, logged: :admin, skip: !Redmine::Plugin.installed?(:redmine_dmsf) do
  let(:project) { FactoryBot.create(:project, add_modules: ['dmsf']) }

  scenario 'dmsf view' do
    visit new_dmsf_path(project)
    wait_for_ajax
    page.find('#dmsf_folder_title').set('testtitle')
    page.find("input[type='submit'").click
    wait_for_ajax
    expect(page.find(".icon-folder").text).to include('testtitle')
    page.find('.js-contextmenu').click
    wait_for_ajax
    page.find('#context-menu .icon-edit').click
    wait_for_ajax
    page.find('.contextual .icon-del').click
    wait_for_ajax
    expect(page.find('.flash.notice')).to have_text(I18n.t(:notice_folder_deleted))
  end

  scenario 'acts as attachable' do
    with_settings(plugin_redmine_dmsf: {'dmsf_act_as_attachable' => '1'}) do
      visit edit_issue_path(project.issues.first)
      expect(page).to have_css('#dmsf_attachments_upload_choice_DMSF')
    end
  end
end
