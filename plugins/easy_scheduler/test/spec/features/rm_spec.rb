require File.expand_path('../../../../../easyproject/easy_plugins/easy_extensions/test/spec/spec_helper', __FILE__)

RSpec.feature 'Scheduler + Resource management', logged: :admin, js: true, if: EasyScheduler.easy_gantt_resources? do

  let(:project) {
    FactoryGirl.create(:project, members: [User.current], add_modules: ['easy_gantt', 'easy_gantt_resources'], number_of_issues: 0)
  }
  let!(:issue) {
    issue = FactoryGirl.create(:issue, project_id: project.id, estimated_hours: 24, start_date: '2018-05-14', due_date: '2018-05-18', assigned_to_id: User.current.id)
    issue.easy_gantt_resources.delete_all
    issue
  }
  let!(:resource) {
    FactoryGirl.create(:easy_gantt_resource, issue: issue, hours: 5, date: '2018-05-16', start: '2018-05-16 12:00')
  }

  around(:each) do |example|
    with_settings(rest_api_enabled: 1) { example.run }
  end

  describe 'RM -> Scheduler' do
    it 'transfer custom allocations' do
      visit easy_scheduler_personal_path(anchor: 'date=2018-05-14&mode=week')
      wait_for_ajax
      expect(page).to have_css('.dhx_cal_event')
      event = page.find('.dhx_cal_event')
      expect(event).to have_text(issue.subject)
      expect(event).to have_text('5h')
    end
  end
end
