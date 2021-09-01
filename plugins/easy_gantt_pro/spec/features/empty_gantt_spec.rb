require File.expand_path('../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)

RSpec.feature 'Empty gantt', logged: :admin, js: true do
  let!(:project) { FactoryGirl.create(:project, add_modules: ['easy_gantt'], number_of_issues: 0) }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1, text_formatting: 'textile') { example.run }
  end
  it 'should show AddTask button' do
    regex = Regexp.new(I18n.t(:label_issue_new), Regexp::IGNORECASE)
    [false, true].each do |pipeline|
      visit easy_gantt_path(project, combine_by_pipeline: pipeline)
      wait_for_ajax
      within('#content') do
        expect(page).to have_text(regex)
      end
    end
  end
end
