require 'easy_extensions/spec_helper'

describe EasyAttendance do

  subject { FactoryBot.create(:easy_attendance, user: User.current) }

  describe '.visible' do
    context 'user with view_easy_attendance_other_users permission' do
      include_context 'logged as with permissions', :view_easy_attendance_other_users

      it 'returns scope all' do
        expect(described_class.visible).to eq(described_class.all)
      end
    end

    context 'user without view_easy_attendance_other_users permission' do
      it 'returns scope with user condition for User.current' do
        expect(described_class.visible).to eq(described_class.where(user: User.current))
      end
    end
  end

  it 'office range' do
    setting = ActionController::Parameters.new({office_ip_range: ['192.168.0.1']})
    allow(Setting).to receive(:plugin_easy_attendances).and_return(setting)
    begin
      expect(EasyAttendance.office_ip_range).to eq([IPAddr.new('192.168.0.1')])
    ensure
      allow(Setting).to receive(:plugin_easy_attendances).and_call_original
    end
  end

  describe 'basic tests' do

    let(:user) {FactoryGirl.create(:user)}
    let(:full_day_week_easy_attendance) {
      attendance = FactoryGirl.build(:full_day_easy_attendance)
      attendance.user = User.current
      attendance.arrival = Date.new(2014, 11, 17)
      attendance.departure = Date.new(2014, 11, 21)
      attendance.easy_attendance_activity = vacation_activity
      attendance
    }
    let(:full_day_second_week_easy_attendance) {
      attendance = FactoryBot.build(:full_day_easy_attendance)
      attendance.user = User.current
      attendance.arrival = Date.new(2014, 11, 24)
      attendance.departure = Date.new(2014, 11, 28)
      attendance.easy_attendance_activity = vacation_activity
      attendance
    }
    let(:half_day_week_easy_attendance) {
      attendance = FactoryGirl.build(:half_day_easy_attendance)
      attendance.user = User.current
      attendance.arrival = User.current.user_civil_time_in_zone(2014,11,17,8,0)
      attendance.departure = User.current.user_civil_time_in_zone(2014, 11, 21,12,0)
      attendance.easy_attendance_activity = vacation_activity
      attendance
    }
    let(:afternoon_week_easy_attendance) {
      attendance = FactoryGirl.build(:afternoon_easy_attendance)
      attendance.user = User.current
      attendance.arrival = User.current.user_civil_time_in_zone(2014, 11, 17,12,0)
      attendance.departure = User.current.user_civil_time_in_zone(2014, 11, 21,16,0)
      attendance.easy_attendance_activity = vacation_activity
      attendance
    }
    let(:full_day_two_weeks_easy_attendance) {
      attendance = FactoryGirl.build(:full_day_easy_attendance)
      attendance.user = User.current
      attendance.arrival = Date.new(2014, 11, 17)
      attendance.departure = Date.new(2014, 11, 28)
      attendance.easy_attendance_activity = vacation_activity
      attendance
    }
    let!(:vacation_activity)  { FactoryGirl.create(:vacation_easy_attendance_activity) }
    let!(:easy_attendance_activity)  { FactoryGirl.create(:easy_attendance_activity) }
    let!(:time_entry_activity) { FactoryGirl.create(:time_entry_activity) }
    let!(:project) { FactoryGirl.create(:project) }
    let!(:time_entry) { FactoryGirl.create(:time_entry) }

    it 'create basic attendance' do

      arrival     = "2014-06-07 12:01".to_time(:local)
      departure   = "2014-06-07 14:17".to_time(:local)

      easy_attendance = EasyAttendance.new(:user => user, :arrival => arrival, :departure => departure)
      easy_attendance.easy_attendance_activity = easy_attendance_activity

      expect(easy_attendance.save!).to be true

      if EasySetting.value(:round_easy_attendance_to_quarters)
        expect(easy_attendance.arrival.to_time).to eq(arrival.round_min_to_quarters)
      else
        expect(easy_attendance.arrival.to_time).to eq(arrival)
      end

    end

    it 'create holidays' do

      arrival     = "2014-06-07 12:01".to_time(:local)
      departure   = "2014-06-11 17:17".to_time(:local)

      expect(EasyAttendance.count).to eq(0)

      easy_attendance = EasyAttendance.new(:user => user, :arrival => arrival, :departure => departure, :easy_attendance_activity_id => easy_attendance_activity.id)
      expect(easy_attendance.save!).to be true

      if EasySetting.value(:round_easy_attendance_to_quarters)
        expect(easy_attendance.arrival.localtime.to_time).to eq((arrival + 2.days).round_min_to_quarters)
        expect(easy_attendance.departure.localtime.to_time).to eq("2014-06-09 17:30".to_time(:local).round_min_to_quarters)
      else
        expect(easy_attendance.arrival.localtime.to_time).to eq(arrival + 2.days)
        expect(easy_attendance.departure.localtime.to_time).to eq("2014-06-09 17:17".to_time(:local))
      end

      expect( EasyAttendance.count ).to eq(3)

    end

    it 'create correctly binded attendance' do

      arrival     = "2014-06-07 12:01".to_time(:local)
      departure   = "2014-06-07 14:17".to_time(:local)

      eaa = easy_attendance_activity
      eaa.update(:project_mapping => true, :mapped_project_id => time_entry.project.id, :mapped_time_entry_activity_id => time_entry_activity.id)

      easy_attendance = EasyAttendance.new(:user => user, :arrival => arrival, :departure => departure, :easy_attendance_activity_id => eaa.id)

      expect{ easy_attendance.save }.to change(TimeEntry, :count).by(1)
    end

    it 'working in office at midnight' do

      arrival     = "2014-06-11 19:01".to_time(:local)
      departure   = "2014-06-12 03:17".to_time(:local)

      expect(EasyAttendance.count).to eq(0)

      easy_attendance = EasyAttendance.new(:user => user, :arrival => arrival, :departure => departure, :easy_attendance_activity_id => easy_attendance_activity.id)

      expect(easy_attendance.save).to be true

      expect(EasyAttendance.count).to eq(2)

      easy_attendance_d1 = EasyAttendance.order(:arrival).first
      easy_attendance_d2 = EasyAttendance.order(:arrival).last

      if EasySetting.value(:round_easy_attendance_to_quarters)
        expect(easy_attendance_d1.arrival.localtime.to_time).to eq(arrival.round_min_to_quarters)
        expect(easy_attendance_d2.departure.localtime.to_time.to_s).to eq(departure.round_min_to_quarters.to_s)
      else
        expect(easy_attendance_d1.arrival.localtime.to_time).to eq(arrival)
        expect(easy_attendance_d2.departure.localtime.to_time.to_s).to eq(departure.to_s)
      end

      expect(easy_attendance_d1.departure.localtime.to_time.to_s).to eq("2014-06-11 23:59:59".to_time(:local).to_s)
      expect(easy_attendance_d2.arrival.localtime.to_time).to eq("2014-06-12 00:00:00".to_time(:local))

    end

    it 'come first day and leave from office next day' do

      arrival     = "2014-06-11 19:01".to_time(:local)
      departure   = "2014-06-12 03:17".to_time(:local)

      expect(EasyAttendance.count).to eq(0)

      easy_attendance = EasyAttendance.new(:user => user, :arrival => arrival, :departure => departure, :easy_attendance_activity_id => easy_attendance_activity.id)

      expect(easy_attendance.save!).to be true

      expect(EasyAttendance.count).to eq(2)

      easy_attendance_d1 = EasyAttendance.order(:arrival).first
      easy_attendance_d2 = EasyAttendance.order(:arrival).last

      if EasySetting.value(:round_easy_attendance_to_quarters)
        expect(easy_attendance_d1.arrival.localtime.to_time).to eq(arrival.round_min_to_quarters)
        expect(easy_attendance_d2.departure.localtime.to_time.to_s).to eq(departure.round_min_to_quarters.to_s)
      else
        expect(easy_attendance_d1.arrival.localtime.to_time).to eq(arrival)
        expect(easy_attendance_d2.departure.localtime.to_time.to_s).to eq(departure.to_s)
      end

      expect(easy_attendance_d1.departure.localtime.to_time.to_s).to eq("2014-06-11 23:59:59".to_time(:local).to_s)
      expect(easy_attendance_d2.arrival.localtime.to_time).to eq("2014-06-12 00:00:00".to_time(:local))

    end

    it 'returns correct values from in_days functions' do
      limit = User.current.easy_attendance_activity_user_limits.build(:easy_attendance_activity_id => vacation_activity.id)

      limit.days = 1.0
      limit.save

      expect( limit.easy_attendance_activity.user_vacation_limit_in_days(User.current) ).to eq 1.0
      expect( limit.easy_attendance_activity.user_vacation_limit_in_days_with_empty(User.current) ).to eq 1.0
      expect( limit.easy_attendance_activity.user_vacation_limit_in_days_with_empty(User.current.dup) ).to be nil
    end

    it 'does not allow to add vacation for approval over limit' do
      limit = User.current.easy_attendance_activity_user_limits.build(:easy_attendance_activity_id => vacation_activity.id)

      limit.days = 6.0
      limit.save

      full_day_week_easy_attendance.save
      expect(full_day_week_easy_attendance.easy_attendance_vacation_limit_valid?(true)).to eq(true)
      full_day_second_week_easy_attendance.save
      expect(full_day_second_week_easy_attendance.easy_attendance_vacation_limit_valid?(true)).to eq(false)
    end

    it 'creates vacation easy attendance with APPOVAL_WAITING approval status' do
      full_day_week_easy_attendance.save

      attendances = full_day_week_easy_attendance.factorized_attendances + [full_day_week_easy_attendance]

      attendances.each do |attendance|
        expect( attendance.approval_status ).to be EasyAttendance::APPROVAL_WAITING
      end
    end

    it 'creates attendance for a week in the morning and the in the afternoon' do
      half_day_week_easy_attendance.save
      expect(afternoon_week_easy_attendance.save).to be true
      expect(full_day_week_easy_attendance.save).to be false
    end

    it 'validates overlapping attendance' do
      user = FactoryGirl.create(:admin_user)
      pref = user.pref
      pref.time_zone = 'Ulaanbaatar'
      pref.save
      expect(user.time_zone).not_to eq(nil)

      attendance = FactoryGirl.build(:afternoon_easy_attendance, :user => user, :easy_attendance_activity => vacation_activity)
      attendance.arrival = user.user_civil_time_in_zone(2014, 11, 17, 6, 0)
      attendance.departure = user.user_civil_time_in_zone(2014, 11, 17, 10, 0)
      expect(attendance.save).to eq(true)
      new_attendance = attendance.dup

      new_attendance.arrival = attendance.departure
      new_attendance.departure = attendance.departure + 1.hours
      expect(new_attendance.valid?).to eq(true)

      new_attendance.arrival = attendance.arrival - 1.hours
      new_attendance.departure = attendance.arrival
      expect(new_attendance.valid?).to eq(true)

      new_attendance.arrival = user.user_civil_time_in_zone(2014, 11, 17, 5, 0)
      new_attendance.departure = user.user_civil_time_in_zone(2014, 11, 17, 9, 0)
      expect(new_attendance.valid?).to eq(false)

      new_attendance.arrival = attendance.arrival - 1.hour
      new_attendance.departure = attendance.arrival + 1.hour
      expect(new_attendance.valid?).to eq(false)
    end

    it 'validates recurring attendance', logged: :admin do
      attendance = FactoryGirl.build(:afternoon_easy_attendance, :user => user, :easy_attendance_activity => vacation_activity)
      attendance.arrival = user.user_civil_time_in_zone(2014, 11, 18, 6, 0)
      attendance.departure = user.user_civil_time_in_zone(2014, 11, 18, 10, 0)
      expect(attendance.save).to eq(true)
      new_attendance = attendance.dup

      new_attendance.arrival = attendance.arrival - 1.day
      new_attendance.departure = attendance.departure + 1.day
      expect(new_attendance.save).to be_falsey
      expect(new_attendance.errors.messages).not_to be_blank
    end

    describe '#reset_approval?' do
      let(:attendance) { FactoryBot.create(:easy_attendance, user: User.current, easy_attendance_activity: vacation_activity, arrival: Time.new(2020, 1, 1, 7, 00), departure: Time.new(2020, 1, 1, 14, 00)) }
      it 'change time' do
        attendance.departure = Time.new(2020, 1, 2, 14, 00)
        expect(attendance.reset_approval?).to be true
      end

      it 'set same time' do
        attendance.departure = Time.new(2020, 1, 1, 14, 00)
        expect(attendance.reset_approval?).to be false
      end

      it 'change description' do
        attendance.description = 'describe self'
        expect(attendance.reset_approval?).to be false
      end
    end

  end

  describe '.approve_attendances', :logged => :admin do
    let(:updated_attendances) { EasyAttendance.where(:id => attendances.collect(&:id)) }

    context 'when approval is awaited' do
      let(:attendances) { FactoryGirl.create_list(:vacation_easy_attendance, 2, :approval_status => EasyAttendance::APPROVAL_WAITING, :previous_approval_status => nil) }

      it 'approves attendances and preserves previous status' do
        approved = EasyAttendance.approve_attendances(attendances.collect(&:id), '1', nil)

        expect(approved[:saved]).not_to be_empty
        expect(approved[:unsaved]).to be_empty
        expect(updated_attendances.pluck(:approval_status).uniq).to eq([EasyAttendance::APPROVAL_APPROVED])
        expect(updated_attendances.pluck(:previous_approval_status).uniq).to eq([EasyAttendance::APPROVAL_WAITING])
      end
    end

    context 'when cancel requested' do
      let(:attendances) { FactoryGirl.create_list(:vacation_easy_attendance, 2, :approval_status => EasyAttendance::CANCEL_WAITING, :previous_approval_status => EasyAttendance::APPROVAL_APPROVED) }

      context 'when request approved' do
        it 'cancels attendances and preserves previous status' do
          approved = EasyAttendance.approve_attendances(attendances.collect(&:id), '1', nil)

          expect(approved[:saved]).not_to be_empty
          expect(approved[:unsaved]).to be_empty
          expect(updated_attendances.pluck(:approval_status).uniq).to eq([EasyAttendance::CANCEL_APPROVED])
          expect(updated_attendances.pluck(:previous_approval_status).uniq).to eq([EasyAttendance::CANCEL_WAITING])
        end
      end

      context 'when request rejected' do
        it 'set attendance to previous approval status' do
          approved = EasyAttendance.approve_attendances(attendances.collect(&:id), '0', nil)

          expect(approved[:saved]).not_to be_empty
          expect(approved[:unsaved]).to be_empty
          expect(updated_attendances.pluck(:approval_status).uniq).to eq([EasyAttendance::APPROVAL_APPROVED])
          expect(updated_attendances.pluck(:previous_approval_status).uniq).to eq([attendances.first.approval_status])
        end
      end

      context 'invalid attendance' do
        it 'should do rollback' do
          last_attendance = attendances.last
          last_attendance.update_columns(departure: last_attendance.arrival, approval_status: EasyAttendance::APPROVAL_WAITING)
          last_attendance.reload
          expect(last_attendance.valid?).to eq(false)
          approved = EasyAttendance.approve_attendances(attendances.collect(&:id), '1', nil)

          expect(approved[:unsaved]).to eq [last_attendance]
          expect(updated_attendances.pluck(:approval_status).uniq).not_to eq([EasyAttendance::CANCEL_APPROVED])
          expect(updated_attendances.pluck(:previous_approval_status).uniq).not_to eq([EasyAttendance::CANCEL_WAITING])
        end
      end
    end
  end

  it '#spent_time' do
    attendance = FactoryBot.create(:easy_attendance, departure: nil, user: User.current)
    expect(attendance.spent_time).to eq(0.0)
  end

  describe '.update_activity_on_office', logged: :admin do

    let(:activity_office) { FactoryBot.create(:easy_attendance_activity, at_work: true) }
    let(:activity_home_office) { FactoryBot.create(:easy_attendance_activity, at_work: true) }
    let(:activity_sick) { FactoryBot.create(:easy_attendance_activity, at_work: false) }

    before(:each) do
      allow(Setting).to receive(:plugin_easy_attendances).and_return('office_ip_range' => ['192.168.0.2'])
      allow(EasyAttendanceActivity).to receive(:for_ip).and_return(activity_office)
      allow(User.current).to receive(:current_attendance).and_return(attendance)
    end

    context 'with home office activity' do
      let(:attendance) { FactoryBot.create(:easy_attendance, easy_attendance_activity: activity_home_office, user: User.current) }

      it 'change on office' do
        with_user_pref('last_easy_attendance_user_ip' => '100.0.0.1') do
          described_class.update_activity_on_office(User.current, '192.168.0.2')
          expect(attendance.activity).to eq(activity_office)
        end
      end

      context 'with mask' do
        it 'change on office' do
          allow(Setting).to receive(:plugin_easy_attendances).and_return('office_ip_range' => ['192.168.0.13/255.255.255.255'])
          with_user_pref('last_easy_attendance_user_ip' => '100.0.0.1') do
            described_class.update_activity_on_office(User.current, '192.168.0.13')
            expect(attendance.activity).to eq(activity_office)
          end
        end
      end
    end

    context 'with sick activity' do
      let(:attendance) { FactoryBot.create(:easy_attendance, easy_attendance_activity: activity_sick, user: User.current) }

      it 'not change' do
        with_user_pref('last_easy_attendance_user_ip' => '100.0.0.1') do
          described_class.update_activity_on_office(User.current, '192.168.0.2')
          expect(attendance.activity).to eq(activity_sick)
        end
      end
    end

  end

  describe '.round_hours_for_day' do

    it 'hours <= 0' do
      expect(described_class.round_hours_for_day(0.0)).to eq(0.0)
    end

    context 'with hours setting' do
      it 'hours <= half_working_hours' do
        expect(described_class.round_hours_for_day(4.0, 8.0, 4.0, true)).to eq(4.0)
      end

      it 'hours > (0 && half_working_hours)' do
        expect(described_class.round_hours_for_day(6.0, 8.0, 4.0, true)).to eq(8.0)
      end
    end

    it 'hours > (0 && half_working_hours)' do
      expect(described_class.round_hours_for_day(6.0, 8.0, 4.0, false)).to eq(1.0)
    end
  end

  it '.office_ip_array' do
    with_settings('plugin_easy_attendances' => {'office_ip_range' => 'ff' }) do
      expect(described_class.office_ip_array).to eq([])
    end
  end

  context 'round minutes' do
    around(:each) do |ex|
      with_easy_settings(round_easy_attendance_to_quarters: true) do
        ex.run
      end
    end

    it 'within day' do
      arrival     = "2014-06-07 12:01".to_time(:local)
      departure   = "2014-06-07 14:17".to_time(:local)
      attendance = FactoryBot.build(:easy_attendance, arrival: arrival, departure: departure, user: User.current, easy_attendance_activity_id: subject.easy_attendance_activity_id)
      expect(attendance.arrival).to eq("2014-06-07 12:15".to_time(:local))
      expect(attendance.departure).to eq("2014-06-07 14:30".to_time(:local))
    end

    it 'end of day' do
      arrival     = "2014-06-07 12:01".to_time(:local)
      departure   = "2014-06-07 23:58".to_time(:local)
      attendance = FactoryBot.build(:easy_attendance, arrival: arrival, departure: departure, user: User.current, easy_attendance_activity_id: subject.easy_attendance_activity_id)
      expect(attendance.arrival).to eq("2014-06-07 12:15".to_time(:local))
      expect(attendance.departure).to be_within(1).of("2014-06-07 23:59:59".to_time(:local))
    end
  end

  it '.new_or_last_attendance' do
    time_now = Time.parse('2019-03-15 15:00')
    FactoryBot.create(:easy_attendance, departure: nil, user: User.current)
    allow(User.current).to receive(:user_time_in_zone).and_return(time_now)
    attendance = described_class.new_or_last_attendance
    expect(attendance.departure.to_s).to eq(time_now.utc.to_s)
  end

  it '.create_departure' do
    time_now = Time.parse('2019-03-15 15:00')

    yesterday_attendance = FactoryBot.create(:easy_attendance, arrival: (time_now - 1.day), departure: nil, user: User.current, easy_attendance_activity_id: subject.easy_attendance_activity_id)
    allow(Time).to receive(:now).and_return(time_now)
    subject.departure = nil
    subject.arrival = time_now - 1.hour

    described_class.create_departure(subject, '192.165.0.1')
    expect(subject.departure_user_ip).to eq('192.165.0.1')
    expect(subject.departure).to eq(time_now.utc)
    expect(yesterday_attendance.reload.departure.to_s).to eq(yesterday_attendance.arrival.localtime.end_of_day.utc.to_s)
  end

  describe '.create_arrival_or_departure', logged: :admin do

    it 'create arrival' do
      allow_any_instance_of(User).to receive(:today).and_return(Date.new(2019, 04, 25))
      allow_any_instance_of(User).to receive(:user_time_in_zone).and_return(Time.parse('2019-04-25 09:00'))
      with_user_pref('last_easy_attendance_arrival_date' => Date.new(2019, 04, 23)) do
        expect { described_class.create_arrival_or_departure(User.current, '192.165.0.1') }.to change(EasyAttendance, :count).by(1)
      end
    end

    it 'create departure' do
      allow_any_instance_of(User).to receive(:current_attendance).and_return(subject)
      subject.departure = nil
      described_class.create_arrival_or_departure(User.current, '192.165.0.1')
      expect(subject.departure).not_to eq(nil)
    end
  end

  it '#arrival?' do
    subject.new_arrival = true
    expect(subject.arrival?).to be true
  end

  it '#departure?' do
    expect(subject.departure?).to be true
  end

  it '#visible_custom_field_values' do
    expect(subject.visible_custom_field_values).to eq([])
  end

  it '#attachments' do
    expect(subject.attachments).to eq([])
  end

  describe '#round_time' do
    it 'valid string' do
      expect(subject.round_time('2019-03-18 17:38:34')).to eq(Time.parse('2019-03-18 17:45:00'))
    end

    it 'invalid string' do
      expect(subject.round_time('haf')).to eq(nil)
    end
  end

  it '#delete_time_entry_on_rejected' do
    FactoryBot.create(:time_entry, easy_attendance: subject)
    expect{ subject.delete_time_entry_on_rejected }.to change(TimeEntry, :count).from(1).to(0)
  end

  it '#activity_was' do
    expect(subject.activity_was).to eq(subject.easy_attendance_activity)
  end

  it '#need_approve?' do
    activity = FactoryBot.create(:easy_attendance_activity, approval_required: false)
    subject.easy_attendance_activity = activity
    expect(subject.need_approve?).to be false
  end

  it '#after_cancel_send_mail' do
    ActionMailer::Base.deliveries = []
    allow(subject).to receive(:approval_mail).and_return('easy.attendance@easy.com')
    subject.after_cancel_send_mail
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  describe '#faktorize_attendances' do
    let(:activity) { FactoryBot.create(:easy_attendance_activity, approval_required: false) }
    let(:working_exception) { FactoryBot.create(:easy_user_time_calendar_exception,
                                                calendar: User.current.current_working_time_calendar,
                                                working_hours: 4.0,
                                                exception_date: Date.new(2019, 12, 03)) }
    let(:invalid_attendance) { FactoryBot.build(:easy_attendance, user: User.current, easy_attendance_activity: activity, arrival: Date.new(2019, 5, 30), departure: Date.new(2019, 5, 28)) }
    let(:attendance) { FactoryBot.build(:full_day_easy_attendance, user: User.current, easy_attendance_activity: activity, arrival: Date.new(2019, 12, 02), departure: Date.new(2019, 12, 03)) }

    it 'arrival older than departure' do
      expect(invalid_attendance.save).to be_falsey

      departure_errors = invalid_attendance.errors.details.fetch(:departure, {})
      expect(departure_errors).to include(error: I18n.t('easy_attendance.departure_is_less_than_arrival'))
    end

    it 'departure by working calendar' do
      working_exception
      User.current.current_working_time_calendar.reload
      attendance.save
      expect(attendance.hours).to eq(9.0)
      factorized_attendance = attendance.attendances_created_from_range.detect { |a| a.arrival.to_date ==  Date.new(2019, 12, 03) }
      expect(factorized_attendance.hours).to eq(4.0)
    end

    it 'validate faktorized attendances' do
      existed = FactoryBot.create(:full_day_easy_attendance, user: User.current, easy_attendance_activity: activity, arrival: Date.new(2019, 12, 03), departure: Date.new(2019, 12, 03))
      expect(attendance.valid?).to be_truthy
      expect { attendance.ensure_faktorized_attendances }.not_to change { EasyAttendance.count }
      expect(attendance.errors.full_messages).to match_array(["Date is already taken by another activity."])
    end

  end
end
