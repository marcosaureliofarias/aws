require 'easy_extensions/spec_helper'

describe EasyTimesheet, logged: :admin do
  let(:easy_timesheet) { FactoryBot.create(:easy_timesheet, start_date: Date.new(2017, 10, 23), end_date: Date.new(2017, 10, 23).end_of_week, user_id: User.current.id) }
  let(:time_entry) { FactoryBot.create(:time_entry, user: User.current, spent_on: Date.new(2017, 11, 23)) }
  let(:easy_attendance_activity) { FactoryBot.create(:easy_attendance_activity, project_mapping: true, mapped_project_id: time_entry.project_id, mapped_time_entry_activity_id: time_entry.activity_id) }
  let(:easy_attendance) { FactoryBot.create(:easy_attendance, user: User.current, arrival: Date.new(2017, 10, 23), departure: Date.new(2017, 10, 23), easy_attendance_activity: easy_attendance_activity) }

  it 'destroy does not destroy time entries with attendance' do
    easy_attendance; easy_timesheet
    easy_timesheet.time_entries << easy_attendance.time_entry
    row = easy_timesheet.rows.first
    row.destroy(true)

    expect(row.time_entries.count).to eq(1)
  end if Redmine::Plugin.installed?(:easy_attendances)

  it 'validation' do
    with_easy_settings(easy_timesheets_enabled_timesheet_calendar: 'week') do
      easy_timesheet
      ts = easy_timesheet.dup
      expect(ts.valid?).to eq(false)
      ts.start_date = Date.new(2017, 10, 1)
      ts.end_date = Date.new(2017, 10, 27)
      expect(ts.valid?).to eq(false)
      ts.start_date = Date.new(2017, 10, 24)
      ts.end_date = Date.new(2017, 10, 24).end_of_week
      expect(ts.valid?).to eq(false)
      ts.start_date = Date.new(2017, 10, 30)
      ts.end_date = Date.new(2017, 10, 30).end_of_week
      expect(ts.valid?).to eq(true)
      ts.write_attribute(:start_date, Date.new(2017, 10, 25))
      ts.end_date = Date.new(2017, 10, 26)
      expect(ts.valid?).to eq(false)
    end
  end

  it 'fake time entry should be for timesheet user' do
    user_timesheet = FactoryBot.create(:easy_timesheet, start_date: Date.new(2017, 10, 23), end_date: Date.new(2017, 10, 23).end_of_week)
    allow_any_instance_of(EasyTimesheets::EasyTimesheetRowCell).to receive(:project).and_return(time_entry.project)
    allow_any_instance_of(EasyTimesheets::EasyTimesheetRowCell).to receive(:issue).and_return(time_entry.issue)
    allow_any_instance_of(EasyTimesheets::EasyTimesheetRowCell).to receive(:activity).and_return(time_entry.activity)
    new_te_cell = EasyTimesheets::EasyTimesheetRowCell.new(user_timesheet, Date.new(2017, 10, 23))
    expect(new_te_cell.new_time_entry.user).to eq(user_timesheet.user)
  end

  context 'resolve lock' do
    let(:locked_easy_timesheet) { FactoryBot.create(:easy_timesheet, locked: true, start_date: Date.new(2017, 10, 23), end_date: Date.new(2017, 10, 23).end_of_week, user_id: User.current.id) }

    it 'lock' do
      easy_timesheet.lock!
      expect(easy_timesheet.locked).to eq(true)
      expect(easy_timesheet.locked_by_id).to eq(User.current.id)
    end

    it 'unlock' do
      locked_easy_timesheet.unlock!
      expect(locked_easy_timesheet.locked).to eq(false)
      expect(locked_easy_timesheet.unlocked_by_id).to eq(User.current.id)
    end
  end

  context '#copy_rows_from' do
    let(:timesheet_from) { FactoryBot.create(:easy_timesheet) }
    let(:origin_timesheet) { FactoryBot.create(:easy_timesheet) }
    let(:origin_row) { spy('easy_timesheets_row') }
    let(:timesheet_from_row) { spy('easy_timesheets_row') }

    it 'lost origin spent times' do
      allow(origin_timesheet).to receive(:rows).and_return([origin_row])
      allow_any_instance_of(EasyTimesheet).to receive(:build_new_rows_from).and_return([timesheet_from_row])
      expect(origin_timesheet.copy_rows_from(timesheet_from)).to match_array([origin_row, timesheet_from_row])
    end
  end

  it '#ensure_end_date' do
    with_easy_settings(easy_timesheets_enabled_timesheet_calendar: 'week') do
      new_start = easy_timesheet.end_date + 14.days
      easy_timesheet.start_date = new_start
      easy_timesheet.ensure_end_date
      expect(easy_timesheet.end_date).to eq new_start.end_of_week
    end
  end

  it 'default #period' do
    with_easy_settings(easy_timesheets_enabled_timesheet_calendar: 'week') do
      weekly_ts = FactoryBot.create(:easy_timesheet)
      expect(weekly_ts.period).to eq('week')
    end
    with_easy_settings(easy_timesheets_enabled_timesheet_calendar: 'month') do
      weekly_ts = FactoryBot.create(:easy_timesheet)
      expect(weekly_ts.period).to eq('month')
    end
    with_easy_settings(easy_timesheets_enabled_timesheet_calendar: nil) do
      weekly_ts = FactoryBot.create(:easy_timesheet)
      expect(weekly_ts.period).to eq('month')
    end
  end

  context 'extend' do
    include_context 'easy timesheet with rows'

    let(:time_entries_scope) { [] }
    let(:time_entries) { [spy('EasyTimeEntry', cast_value: true), spy('EasyTimeEntry', cast_value: false)] }

    subject { easy_timesheet }

    it '#over_time_rows' do
      expect(subject.over_time_rows.count).to eq(3)
    end

    it '#non_over_time_rows' do
      expect(subject.non_over_time_rows.count).to eq(2)
    end

    it '#working_dates' do
      expect(subject.working_dates.count).to eq(30)
    end

    context 'without active overtime feature' do
      around(:each) do |example|
        with_easy_settings('easy_timesheets_over_time' => '0') { example.run }
      end

      it '#copy_rows_from' do
        new_timesheet = EasyTimesheet.new(period: :month, start_date: '2018-12-1', end_date: '2018-12-31')
        new_timesheet.copy_rows_from(subject)
        expect(new_timesheet.rows.count).to eq(5)
        expect(new_timesheet.over_time_rows.count).to eq(0)
        expect(new_timesheet.non_over_time_rows.count).to eq(5)
      end

      it '#create_timesheet_rows' do
        allow(time_entries_scope).to receive(:reorder).and_return(time_entries)
        rows = subject.create_timesheet_rows(time_entries_scope)
        expect(rows.count).to eq(2)
        expect(rows.first.over_time).to be nil
        expect(rows.second.over_time).to be nil
      end
    end

    context 'with active overtime feature' do
      around(:each) do |example|
        with_easy_settings('easy_timesheets_over_time' => '1') { example.run }
      end

      it '#copy_rows_from' do
        new_timesheet = EasyTimesheet.new(period: :month, start_date: '2018-12-1', end_date: '2018-12-31')
        new_timesheet.copy_rows_from(subject)
        expect(new_timesheet.rows.count).to eq(5)
        expect(new_timesheet.over_time_rows.count).to eq(3)
        expect(new_timesheet.non_over_time_rows.count).to eq(2)
      end

      it '#create_timesheet_rows' do
        allow(time_entries_scope).to receive(:reorder).and_return(time_entries)
        rows = subject.create_timesheet_rows(time_entries_scope)
        expect(rows.count).to eq(2)
        expect(rows.first.over_time).to be true
        expect(rows.second.over_time).to be false
      end
    end

  end
end
