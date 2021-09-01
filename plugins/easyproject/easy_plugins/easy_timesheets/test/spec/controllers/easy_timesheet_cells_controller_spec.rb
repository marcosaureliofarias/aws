
require 'easy_extensions/spec_helper'

describe EasyTimesheetCellsController, type: :controller, logged: :admin do
  let(:easy_timesheet) { FactoryBot.create(:easy_timesheet, start_date: Date.new(2020, 1, 1), end_date: Date.new(2020, 1, 31), period: 'month') }
  let(:project) { FactoryBot.create(:project) }

  context '#create' do

    it 'pass if all parameters are correct' do
      post :create, xhr: true, params: { easy_timesheet_row: { over_time: '', project_id: project.id, issue_id: '', activity_id: 16 }, time_entry: { spent_on: Date.new(2020, 1, 12), hours: 1 }, id: easy_timesheet.id }
      expect(response).to have_http_status(200)
    end

    it 'fail if spent time is nil' do
      post :create, xhr: true, params: { easy_timesheet_row: { over_time: '', project_id: project.id, issue_id: '', activity_id: 16 }, time_entry: { spent_on: '', hours: 1 }, id: easy_timesheet.id }
      expect(response).to have_http_status(404)
    end

  end

end
