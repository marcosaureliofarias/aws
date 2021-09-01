require 'easy_extensions/spec_helper'

describe EasyAttendanceUserQuery, logged: :admin do
  let(:easy_attendance_activity) { FactoryGirl.create(:easy_attendance_activity) }
  let(:easy_attendance_activity2) { FactoryGirl.create(:easy_attendance_activity) }
  let(:start) { Time.now.beginning_of_day }
  let(:easy_attendance) { FactoryGirl.create(:easy_attendance, arrival: start, departure: start + 5.hours, easy_attendance_activity: easy_attendance_activity) }
  let(:time_entry) { FactoryGirl.create(:time_entry, spent_on: Date.today, hours: 5) }

  it 'get values' do
    easy_attendance; time_entry
    q = EasyAttendanceUserQuery.new
    range = q.period_start_date..q.period_end_date
    expect(range).to cover(easy_attendance.arrival)
    expect(range).to cover(time_entry.spent_on)

    q.column_names = ['working_attendance', 'attendance_in_period_diff_working_time', 'time_entry_in_period_diff_working_time']
    expect(q.columns.size).to eq(3)
    vals = q.get_values('easy_attendance')
    expect(vals.size).to eq(1)
    expect(vals.first['sum'].to_f).to eq(5)

    vals = q.get_values('time_entry')
    expect(vals.size).to eq(1)
    expect(vals.first['sum'].to_f).to eq(5)
  end

  it 'selected activity ids from columns' do
    easy_attendance
    easy_attendance_activity2
    q = EasyAttendanceUserQuery.new
    q.column_names = ["eaa_sum_#{easy_attendance_activity.id}", 'working_attendance', 'attendance_in_period_diff_working_time', 'time_entry_in_period_diff_working_time']
    expect(q.columns.size).to eq(4)
    vals = q.get_values('easy_attendance')
    expect(vals.size).to eq(1)
    expect(vals.first['sum'].to_f).to eq(5)

    q = EasyAttendanceUserQuery.new
    q.column_names = ["eaa_sum_#{easy_attendance_activity2.id}", 'working_attendance', 'attendance_in_period_diff_working_time', 'time_entry_in_period_diff_working_time']
    expect(q.columns.size).to eq(4)
    expect(q.get_values('easy_attendance').empty?).to eq(true)
  end

  context 'columns' do
    let(:start) { Time.utc 2019, 3, 1, 9 }
    let(:easy_attendance) { FactoryGirl.create(:easy_attendance, user: User.current, arrival: start, departure: start + 5.hours, easy_attendance_activity: easy_attendance_activity) }
    let(:time_entry) { FactoryGirl.create(:time_entry, user: User.current, spent_on: start + 5.days, hours: 2.5) }

    it 'test working attendance percent values' do
      easy_attendance; time_entry
      q = EasyAttendanceUserQuery.new
      q.column_names = ['time_entry_in_period', 'working_attendance_percent', 'eaa_sum_all']
      q.period_start_date = start.to_date
      q.period_end_date = start.to_date + 1.day

      q.columns.each do |c|
        gen_col_value = c.generate(0, q).value(User.current)
        case c.name
        when :eaa_sum_all
          expect(gen_col_value).to eq(5.0)
        when :time_entry_in_period
          expect(gen_col_value).to eq(2.5)
        when :working_attendance_percent
          expect(gen_col_value).to eq(0.5)
        end
      end
    end
  end

end
