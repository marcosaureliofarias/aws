require 'easy_extensions/spec_helper'

describe EpmAttendance, :logged => :admin do
  describe '#get_show_data with calendar output' do
    let(:attendance_module) { EpmAttendance.new }

    context 'with filter wider than calendar' do
      let!(:settings) { HashWithIndifferentAccess.new("query_type"=>"2", "query_name"=>"Current month attendances", "output"=>"calendar", "period"=>"week", "fields"=>["arrival", "departure", "user_id"], "operators"=>{"arrival"=>"date_period_1", "departure"=>"date_period_1", "easy_attendance_activity_id"=>"=", "approval_status"=>"=", "user_id"=>"*", "arrival_user_ip"=>"=", "departure_user_ip"=>"=", "group_id"=>"="}, "values"=>{"arrival"=>{"period"=>"current_month", "from"=>"2015-07-02", "to"=>"2015-07-03"}, "departure"=>{"period"=>"current_month", "from"=>"2015-07-01", "to"=>"2015-07-03"}, "easy_attendance_activity_id"=>["1"], "approval_status"=>["1"], "user_id"=>["me"], "arrival_user_ip"=>[""], "departure_user_ip"=>[""], "group_id"=>["3"]}) }
      let!(:attendances) do
        {
          :current => [FactoryGirl.create(:easy_attendance, arrival: Date.today.to_time+7.hours, departure: Date.today.to_time+15.hours)],
          :ago => [FactoryGirl.create(:easy_attendance, arrival: (Date.today-1.week).to_time+7.hours, departure: (Date.today-1.week).to_time+15.hours)],
          :next => [FactoryGirl.create(:easy_attendance, arrival: (Date.today+1.week).to_time+7.hours, departure: (Date.today+1.week).to_time+15.hours)]
        }
      end
      it 'contains only calendar range' do
        test_calendar_attendances
      end
    end

    context 'with filter for one day in calendar' do
      let!(:settings) { HashWithIndifferentAccess.new("query_type"=>"2", "query_name"=>"Today attendances", "output"=>"calendar", "period"=>"week", "fields"=>["arrival", "departure", "user_id"], "operators"=>{"arrival"=>"date_period_1", "departure"=>"date_period_1", "easy_attendance_activity_id"=>"=", "approval_status"=>"=", "user_id"=>"*", "arrival_user_ip"=>"=", "departure_user_ip"=>"=", "group_id"=>"="}, "values"=>{"arrival"=>{"period"=>"today", "from"=>"2015-07-02", "to"=>"2015-07-03"}, "departure"=>{"period"=>"today", "from"=>"2015-07-01", "to"=>"2015-07-03"}, "easy_attendance_activity_id"=>["1"], "approval_status"=>["1"], "user_id"=>["me"], "arrival_user_ip"=>[""], "departure_user_ip"=>[""], "group_id"=>["3"]}) }
      let!(:attendances) do
        {
          :current => [FactoryGirl.create(:easy_attendance, arrival: Date.today.to_time+7.hours, departure: Date.today.to_time+15.hours)],
          :ago => [FactoryGirl.create(:easy_attendance, arrival: (Date.today-1.day).to_time+7.hours, departure: (Date.today-1.day).to_time+15.hours)],
          :next => [FactoryGirl.create(:easy_attendance, arrival: (Date.today+1.day).to_time+7.hours, departure: (Date.today+1.day).to_time+15.hours)]
        }
      end

      it 'contains only one day' do
        test_calendar_attendances
      end
    end
  end
end

def test_calendar_attendances
  calendar = attendance_module.get_show_data(settings, User.current)[:calendar]

  expect(calendar.events.count).to eq(attendances[:current].count)
end
