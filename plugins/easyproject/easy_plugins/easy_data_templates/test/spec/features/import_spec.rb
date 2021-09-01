require 'easy_extensions/spec_helper'

feature 'msp import', js: true, logged: :admin do
  let(:cf_list) { FactoryBot.create(:issue_custom_field, field_format: 'list', is_required: true, possible_values: ['aaa', 'bbb'], default_value: 'bbb') }
  let(:import) { FactoryBot.create(:easy_data_template_ms_project) }
  let(:xml) { FactoryBot.create(:attachment, container: import, file: IO.read(File.join(File.dirname(__FILE__) + '/../../fixtures/files', 'msp.xml'))) }
  let(:tracker) { FactoryBot.create(:tracker) }
  let(:status) { FactoryBot.create(:issue_status) }
  let(:priority) { FactoryBot.create(:issue_priority) }

  scenario 'preview' do
    cf_list; xml; tracker; status; priority; import.reload
    visit url_for(controller: 'easy_data_template_ms_projects', action: 'import_settings', id: import, only_path: true)
    wait_for_ajax
    expect(page.find('#project_name').value).to eq('msproj11')
    page.find(".form-actions input[type='submit']").click
    wait_for_ajax
    expect(page).to have_css(".flash.notice", text: I18n.t(:notice_easy_data_templates_import_ok))
  end
end
