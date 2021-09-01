require 'easy_extensions/spec_helper'

RSpec.describe Issue, type: :model, logged: :admin do

  # 4.1.2016 is monday
  # 10.1.2016 is sunday

  let(:user) { FactoryGirl.create(:user) }
  let(:issue) { FactoryGirl.create(:issue, assigned_to: user) }
  let(:user2) { FactoryGirl.create(:user) }
  let(:group) {
    _group = FactoryGirl.create(:group)
    _group.users = [user, user2]
    _group
  }

  around(:each) do |example|
    with_easy_settings(
      easy_gantt_resources_advance_hours_definition: false,
      easy_gantt_resources_hours_per_day: 8,
      easy_gantt_resources_default_allocator: 'from_end'
    ) { example.run }
  end

  context 'Allocations' do

    def test_allocations(start: nil, due: nil, estimate: nil, assignee: nil, **allocations)
      start = Date.parse(start) if start
      due = Date.parse(due) if due

      allocations = allocations.map{|d, h| [Date.parse(d.to_s), h.to_f] }

      issue.start_date = start
      issue.due_date = due
      issue.estimated_hours = estimate
      issue.assigned_to = assignee || user

      issue.reallocate_resources
      issue.instance_variable_set(:@allocated_hours, nil)
      issue.reload

      resources = issue.easy_gantt_resources.where('hours > 0').
                                             order(:date).
                                             map{|r| [r.date, r.hours.to_f] }

      original_resources = issue.easy_gantt_resources.where('hours > 0').
                                                      order(:date).
                                                      map{|r| [r.date, r.original_hours.to_f] }

      expect(resources).to eq(allocations)
      expect(original_resources).to eq(allocations)
      expect(issue.allocated_hours).to eq(allocations.sum{|(_, hours)| hours })
    end

    it 'With start and due date' do
      test_allocations(
        start: '04-01-2016',
        due: '10-01-2016',
        estimate: 20,

        # nothing there
        :'06-01-2016' => 4,
        :'07-01-2016' => 8,
        :'08-01-2016' => 8
        # weekend
      )
    end

    it 'With start date' do
      test_allocations(
        start: '04-01-2016',
        estimate: 20,

        :'04-01-2016' => 8,
        :'05-01-2016' => 8,
        :'06-01-2016' => 4
      )
    end

    it 'With due date' do
      test_allocations(
        due: '07-01-2016',
        estimate: 20,

        :'05-01-2016' => 4,
        :'06-01-2016' => 8,
        :'07-01-2016' => 8
      )
    end

    it 'With no date' do
      test_allocations(estimate: 20)
    end

    it 'Large estimated' do
      test_allocations(
        start: '04-01-2016',
        due: '10-01-2016',
        estimate: 100,

        :'04-01-2016' => 8,
        :'05-01-2016' => 8,
        :'06-01-2016' => 8,
        :'07-01-2016' => 8,
        :'08-01-2016' => 68
      )
    end

    it 'Different per user' do
      with_easy_settings(easy_gantt_resources_users_hours_limits: { user2.id.to_s => 2 }) do
        test_allocations(
          start: '04-01-2016',
          due: '10-01-2016',
          estimate: 20,
          assignee: user,

          :'06-01-2016' => 4,
          :'07-01-2016' => 8,
          :'08-01-2016' => 8
        )

        test_allocations(
          start: '04-01-2016',
          due: '10-01-2016',
          estimate: 20,
          assignee: user2,

          :'04-01-2016' => 2,
          :'05-01-2016' => 2,
          :'06-01-2016' => 2,
          :'07-01-2016' => 2,
          :'08-01-2016' => 12
        )
      end
    end

    context 'Decimal' do

      it 'disabled' do
        with_easy_settings(easy_gantt_resources_decimal_allocation: false,
                           easy_gantt_resources_default_allocator: 'evenly') do
          test_allocations(
            start: '04-01-2016',
            due: '07-01-2016',
            estimate: 50.5,

            :'04-01-2016' => 12,
            :'05-01-2016' => 12,
            :'06-01-2016' => 13,
            :'07-01-2016' => 13.5
          )
        end
      end

      it 'enabled' do
        with_easy_settings(easy_gantt_resources_decimal_allocation: true,
                           easy_gantt_resources_default_allocator: 'evenly') do
          test_allocations(
            start: '04-01-2016',
            due: '07-01-2016',
            estimate: 50.5,

            :'04-01-2016' => 12.5,
            :'05-01-2016' => 12.5,
            :'06-01-2016' => 12.5,
            :'07-01-2016' => 13.0
          )

          test_allocations(
            start: '20-05-2019',
            due: '24-05-2019',
            estimate: 9,

            :'20-05-2019' => 1.5,
            :'21-05-2019' => 1.5,
            :'22-05-2019' => 2,
            :'23-05-2019' => 2,
            :'24-05-2019' => 2,
          )
        end
      end

    end

    context 'Evenly' do

      it 'on vacation', skip: !Redmine::Plugin.installed?(:easy_attendance) do
        non_working_attendance = FactoryGirl.create(:easy_attendance_activity, :vacation)

        EasyAttendance.create!(
          arrival: Time.new(2016, 1, 6, 10, 00),
          departure: Time.new(2016, 1, 6, 14, 00),
          user_id: user.id,
          easy_attendance_activity: non_working_attendance,
          approval_status: EasyAttendance::APPROVAL_APPROVED
        )

        # All day should be 0
        with_easy_settings(easy_gantt_resources_default_allocator: 'evenly') do
          test_allocations(
            start: '04-01-2016',
            due: '08-01-2016',
            estimate: 100,

            :'04-01-2016' => 25,
            :'05-01-2016' => 25,
            # nothing
            :'07-01-2016' => 25,
            :'08-01-2016' => 25
          )
        end
      end

    end

    context 'Future' do

      before :each do
        allow(Date).to receive(:today).and_return(Date.new(2016, 1, 6))
      end

      after :each do
        allow(Date).to receive(:today).and_call_original
      end

      it 'Evenly' do
        with_easy_settings(easy_gantt_resources_decimal_allocation: false,
                           easy_gantt_resources_default_allocator: 'future_evenly') do
          # All week
          test_allocations(
            start: '04-01-2016',
            due: '08-01-2016',
            estimate: 23,

            :'06-01-2016' => 7,
            :'07-01-2016' => 8,
            :'08-01-2016' => 8
          )

          # Only in the past
          test_allocations(
            start: '04-01-2016',
            due: '05-01-2016',
            estimate: 23,

            :'05-01-2016' => 23
          )

          # Only in the future
          test_allocations(
            start: '07-01-2016',
            due: '08-01-2016',
            estimate: 20,

            :'07-01-2016' => 10,
            :'08-01-2016' => 10
          )
        end
      end

      it 'From start' do
        with_easy_settings(easy_gantt_resources_default_allocator: 'future_from_start') do
          # All week
          test_allocations(
            start: '04-01-2016',
            due: '08-01-2016',
            estimate: 40,

            :'06-01-2016' => 8,
            :'07-01-2016' => 8,
            :'08-01-2016' => 24
          )

          # Only in the past
          test_allocations(
            start: '04-01-2016',
            due: '05-01-2016',
            estimate: 40,

            :'05-01-2016' => 40
          )

          # Only in the past, withour due date
          test_allocations(
            start: '04-01-2016',
            estimate: 24,

            :'06-01-2016' => 8,
            :'07-01-2016' => 8,
            :'08-01-2016' => 8
          )

          # Only in the future
          test_allocations(
            start: '07-01-2016',
            due: '08-01-2016',
            estimate: 40,

            :'07-01-2016' => 8,
            :'08-01-2016' => 32
          )
        end
      end

      it 'From end' do
        with_easy_settings(easy_gantt_resources_default_allocator: 'future_from_end') do
          # All week
          test_allocations(
            start: '04-01-2016',
            due: '08-01-2016',
            estimate: 23,

            :'06-01-2016' => 7,
            :'07-01-2016' => 8,
            :'08-01-2016' => 8
          )

          # Only in the past
          test_allocations(
            start: '04-01-2016',
            due: '05-01-2016',
            estimate: 23,

            :'05-01-2016' => 23
          )

          # Only in the future
          test_allocations(
            start: '07-01-2016',
            due: '08-01-2016',
            estimate: 20,

            :'07-01-2016' => 8,
            :'08-01-2016' => 12
          )
        end
      end

    end

    context 'On group' do

      it 'no vacation' do
        test_allocations(
          start: '04-01-2016',
          due: '07-01-2016',
          estimate: 24,
          assignee: group,

          :'05-01-2016' => 8,
          :'06-01-2016' => 8,
          :'07-01-2016' => 8
        )
      end

      it 'vacation', skip: !Redmine::Plugin.installed?(:easy_attendance) do
        non_working_attendance = FactoryGirl.create(:easy_attendance_activity, :vacation)

        EasyAttendance.create!(
          arrival: Time.new(2016, 1, 5, 10, 00),
          departure: Time.new(2016, 1, 5, 14, 00),
          user_id: user.id,
          easy_attendance_activity: non_working_attendance,
          approval_status: EasyAttendance::APPROVAL_APPROVED
        )

        test_allocations(
          start: '04-01-2016',
          due: '07-01-2016',
          estimate: 24,
          assignee: group,

          :'04-01-2016' => 2,
          :'05-01-2016' => 6,
          :'06-01-2016' => 8,
          :'07-01-2016' => 8
        )
      end

      it 'holidays' do
        with_easy_settings(easy_gantt_resources_groups_holidays_enabled: true) do
          tc1 = FactoryGirl.create(:easy_user_time_calendar, user: user)
          tc1.holidays << EasyUserTimeCalendarHoliday.new(name: 'Holiday 1', holiday_date: '04-01-2016', ical_uid: SecureRandom.uuid)
          tc1.holidays << EasyUserTimeCalendarHoliday.new(name: 'Holiday 2', holiday_date: '05-01-2016', ical_uid: SecureRandom.uuid)

          tc2 = FactoryGirl.create(:easy_user_time_calendar, user: user2)
          tc2.holidays << EasyUserTimeCalendarHoliday.new(name: 'Holiday 3', holiday_date: '05-01-2016', ical_uid: SecureRandom.uuid)
          tc2.holidays << EasyUserTimeCalendarHoliday.new(name: 'Holiday 4', holiday_date: '06-01-2016', ical_uid: SecureRandom.uuid)

          test_allocations(
            start: '04-01-2016',
            due: '10-01-2016',
            estimate: 100,
            assignee: group,

            :'04-01-2016' => 4,
            # 5.1. is zero
            :'06-01-2016' => 4,
            :'07-01-2016' => 8,
            :'08-01-2016' => 84,
          )
        end
      end

    end

    context 'Custom' do

      def log_time(issue, hours, spent_on)
        TimeEntry.create!(
          issue: issue,
          project: issue.project,
          user: issue.assigned_to,
          hours: hours,
          spent_on: spent_on,
          activity: TimeEntryActivity.first
        )
      end

      def set_issue
        issue.start_date = Date.new(2016, 1, 4)
        issue.due_date = Date.new(2016, 1, 6)
        issue.estimated_hours = 24
        issue.assigned_to = user
        issue.save
      end

      def get_res
        issue.easy_gantt_resources.index_by{|r| r.to_date.to_s }
      end

      it 'Only' do
        set_issue
        issue.easy_gantt_resources.update_all(hours: 8, custom: true)

        issue.reload
        log_time(issue, 4, '2016-04-01')

        res1, res2, res3 = issue.easy_gantt_resources.order(:date).to_a

        expect(res1.custom).to be_falsey
        expect(res1.hours).to eq(4)
        expect(res1.original_hours).to eq(8)

        expect(res2.custom).to be_truthy
        expect(res2.hours).to eq(8)
        expect(res2.original_hours).to eq(8)

        expect(res3.custom).to be_truthy
        expect(res3.hours).to eq(8)
        expect(res3.original_hours).to eq(8)
      end

      it 'Mix (reduce non-custom)' do
        set_issue
        res1, res2, res3 = issue.easy_gantt_resources.order(:date).to_a

        res1.update_columns(custom: true)
        res2.update_columns(custom: true)
        res3.update_columns(custom: false)

        issue.reload
        log_time(issue, 4, '2016-04-01')

        res1, res2, res3 = issue.easy_gantt_resources.order(:date).to_a

        expect(res1.custom).to be_truthy
        expect(res1.hours).to eq(8)
        expect(res1.original_hours).to eq(8)

        expect(res2.custom).to be_truthy
        expect(res2.hours).to eq(8)
        expect(res2.original_hours).to eq(8)

        expect(res3.custom).to be_falsey
        expect(res3.hours).to eq(4)
        expect(res3.original_hours).to eq(8)
      end

      it 'Mix (reduce both)' do
        set_issue
        res1, res2, res3 = issue.easy_gantt_resources.order(:date).to_a

        res1.update_columns(custom: true)
        res2.update_columns(custom: true)
        res3.update_columns(custom: false)

        issue.reload
        log_time(issue, 12, '2016-04-01')

        res1, res2, res3 = issue.easy_gantt_resources.order(:date).to_a

        expect(res1.custom).to be_falsey
        expect(res1.hours).to eq(0)
        expect(res1.original_hours).to eq(8)

        expect(res2.custom).to be_truthy
        expect(res2.hours).to eq(8)
        expect(res2.original_hours).to eq(8)

        expect(res3.custom).to be_falsey
        expect(res3.hours).to eq(4)
        expect(res3.original_hours).to eq(8)
      end

    end

  end
end
