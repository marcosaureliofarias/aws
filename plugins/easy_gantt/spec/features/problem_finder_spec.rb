require File.expand_path('../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)

RSpec.feature 'Problem finder', logged: :admin, js: true do
  let(:superproject) {
    FactoryGirl.create(:project, add_modules: ['easy_gantt'], number_of_issues: 0)
  }
  let!(:issue_1) {
    FactoryGirl.create(:issue, start_date: Date.today+2.days, due_date: Date.today+4.days, project_id: superproject.id)
  }
  let!(:issue_2) {
    FactoryGirl.create(:issue, start_date: Date.today-2.days, due_date: Date.today+2.days, project_id: superproject.id)
  }
  let!(:issue_3) {
    FactoryGirl.create(:issue, start_date: Date.today-4.days, due_date: Date.today-2.days, project_id: superproject.id)
  }
  let(:milestone_1) {
    FactoryGirl.create(:version, due_date: Date.today+6.days, project_id: superproject.id)
  }
  let!(:issue_4) {
    FactoryGirl.create(:issue, start_date: Date.today+2.days, due_date: Date.today+4.days, project_id: superproject.id, fixed_version_id: milestone_1.id)
  }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) { example.run }
  end


  it 'show 2 issues' do
    visit easy_gantt_path(superproject)
    wait_for_ajax
    expect(page).to have_text(issue_1.subject)
    count = page.find('.gantt-menu-problems-count')
    expect(count).to have_text(1)
    page.find('#button_problem_finder').click
    within('#gantt_problem_list') do
      expect(page).to have_text(issue_3.subject)
    end
    move_script= <<-EOF
      (function(){var issue = ysy.data.issues.getByID(#{issue_4.id});
      issue.set({end_date:moment('#{Date.today + 8.days}')});
      return "success";})()
    EOF
    expect(page.evaluate_script(move_script)).to eq('success')
    expect(count).to have_text(2)
    within('#gantt_problem_list') do
      expect(page).to have_text(issue_3.subject)
      expect(page).to have_text(issue_4.subject)
    end
  end
end