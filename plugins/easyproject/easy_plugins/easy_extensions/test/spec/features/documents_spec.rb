require 'easy_extensions/spec_helper'

feature 'documents index', :js => true, :logged => :admin do
  let(:project) { FactoryGirl.create(:project, :add_modules => ['documents']) }

  feature 'with query with filter active' do
    context 'when no data found' do
      scenario 'has query form visible' do
        visit project_documents_path(project, :set_filter => 1, :filesize => '!*|')

        expect(page).to have_text(I18n.t(:label_no_data))
        expect(page).to have_selector("form#query_form") if Redmine::Plugin.installed?(:easy_project_attachments)
      end
    end
  end
end
