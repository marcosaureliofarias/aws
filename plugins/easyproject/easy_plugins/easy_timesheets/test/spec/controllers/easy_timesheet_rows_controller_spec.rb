require 'easy_extensions/spec_helper'

describe EasyTimesheetRowsController, type: :controller, logged: :admin do

  around(:each) do |example|
    with_easy_settings('easy_timesheets_over_time' => '1') { example.run }
  end

  describe 'with over_time' do

    it '#valid' do
      allow(controller).to receive(:find_easy_timesheet).and_return(nil)
      controller.instance_variable_set(:@easy_timesheet, spy)
      post :valid, params: { id: 1, over_time: 'true' }
      expect(assigns(:over_time)).to be true
    end

  end

  describe 'without over_time' do

    it '#valid' do
      allow(controller).to receive(:find_easy_timesheet).and_return(nil)
      controller.instance_variable_set(:@easy_timesheet, spy)
      post :valid, params: { id: 1 }
      expect(assigns(:over_time)).to be false
    end

  end

end
