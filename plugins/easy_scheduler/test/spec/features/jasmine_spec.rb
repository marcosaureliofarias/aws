require File.expand_path('../../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)
RSpec.shared_examples :scheduler_jasmine do |path, example, tags, with_pipeline|
  it 'Jasmine' + (with_pipeline ? ' (pipeline)' : '') do
    visit self.send(path, jasmine: tags, combine_by_pipeline: with_pipeline, anchor:'date=2018-09-17&mode=week')
    expect(page).not_to have_text('SyntaxError')
    wait_for_ajax
    expect(page).to have_css('.jasmine-bar')
    result = page.evaluate_script('jasmineHelper.parseResult();')
    expect(result).to eq('success')
  end
end

RSpec.feature 'Scheduler', logged: :admin, js: true, js_wait: :long do
  around(:each) do |example|
    with_settings(rest_api_enabled: 1) { example.run }
  end
  context 'Personal' do
    include_examples :scheduler_jasmine,:easy_scheduler_personal_path, :scheduler_jasmine, ['personal'], false
    include_examples :scheduler_jasmine,:easy_scheduler_personal_path, :scheduler_jasmine, ['personal'], true
  end
  context 'Manager' do
    include_examples :scheduler_jasmine,:easy_scheduler_path, :scheduler_jasmine, ['manager'], false
    include_examples :scheduler_jasmine,:easy_scheduler_path, :scheduler_jasmine, ['manager'], true
  end
end
