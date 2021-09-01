require 'easy_extensions/spec_helper'

describe EasyMeeting do

  around(:each) do |example|
    with_settings(notified_events: ['meeting']) do
      example.run
    end
  end

  let(:easy_meeting) { FactoryBot.create(:easy_meeting, :with_users) }
  let(:easy_room) { FactoryBot.create(:easy_room) }

  context 'recurring' do

    describe 'create now' do
      before do
        stub_const('EasyMeeting::CREATE_ALL_RECORDS_LIMIT', 1)
      end

      let(:recurring) { FactoryBot.build(:easy_meeting, :reccuring, :with_users, start_time: Time.now + 1.hour) }
      let(:repeater) { EasyRakeTaskRepeatingEntities.new }

      it 'create repeated now' do
        # expect 1 parent and 1 repeated will be created
        expect { recurring.save }.to change { EasyMeeting.count }.from(0).to(2)
                            .and change { EasyCalendarMailer.deliveries.count }.by(4)
        # expect recurring generates uid
        expect(recurring.uid).not_to be_blank

        #expect repeated
        repeated = EasyMeeting.where(easy_repeat_parent_id: recurring.id).last
        expect(repeated.uid).not_to be_blank
        expect(repeated.uid).not_to eq(recurring.uid)
      end

      it 'create now and next by repeater' do
        # expect upcoming repeated events for CREATE_NOW_DAYS days
        expect { recurring.save }.to change { EasyMeeting.count }.by(2)

        # set easy_next_start for test
        recurring.update_column(:easy_next_start, Date.today + 10.days)

        # expect next repeated, which should be created by repeater task
        with_time_travel(2.days) do
          expect { repeater.execute }.to change{ EasyMeeting.count }.by(0)
        end

        # all meetings should be repeated next 7 days
        with_time_travel(3.days) do
          expect { repeater.execute }.to change{ EasyMeeting.count }.from(2).to(3)
        end
      end
    end

    describe '#set_default_repeat_options' do

      shared_examples 'setting default repeat options' do |start_time:, easy_repeat_settings:, expected_next_start:|
        context "with period #{easy_repeat_settings[:period]}" do
          let(:repeated_meeting) do
            FactoryBot.build(
              :easy_meeting,
              :reccuring,
              {
                start_time: start_time,
                easy_repeat_settings: easy_repeat_settings.stringify_keys,
              }
            )
          end

          it 'counts next start' do
            repeated_meeting.set_default_repeat_options
            expect(repeated_meeting.easy_next_start).to eq(expected_next_start)
          end

        end
      end

      it_behaves_like 'setting default repeat options', {
        start_time: Time.local(2019, 2, 7, 8),
        easy_repeat_settings: {
          simple_period: 'custom',
          period: 'daily',
          daily_option: 'work',
          daily_work_x: '30',
          endtype: 'endless',
        },
        expected_next_start: Date.new(2019, 3, 21)
      }
      it_behaves_like 'setting default repeat options', {
        start_time: Time.local(2019, 2, 7, 8),
        easy_repeat_settings: {
          simple_period: 'custom',
          period: 'weekly',
          week_days: ['2'],
          endtype: 'endless',
        },
        expected_next_start: Date.new(2019, 2, 12)
      }
      it_behaves_like 'setting default repeat options', {
        start_time: Time.local(2019, 2, 1, 8),
        easy_repeat_settings: {
          simple_period: 'custom',
          period: 'monthly',
          monthly_option: 'xth',
          monthly_day: '1',
          monthly_period: '1',
          endtype: 'endless',
        },
        expected_next_start: Date.new(2019, 2, 1)
      }
      it_behaves_like 'setting default repeat options', {
        start_time: Time.local(2019, 1, 1, 8),
        easy_repeat_settings: {
          simple_period: 'custom',
          period: 'yearly',
          yearly_option: 'date',
          yearly_month: '1',
          yearly_day: '1',
          yearly_period: '1',
          endtype: 'endless',
        },
        expected_next_start: Date.new(2019, 1, 1)
      }

    end
  end

  context 'room conflicts' do
    let(:start_time) { Time.new(2018, 1, 1, 2) }
    let(:end_time) { Time.new(2018, 1, 1, 3) }
    let!(:meeting) { FactoryBot.create(:easy_meeting, user_ids: [User.current.id], easy_room: easy_room, start_time: start_time, end_time: end_time) }

    it 'validates room conflict', logged: :admin do
      conflict_meeting = FactoryBot.build(:easy_meeting, user_ids: [User.current.id], easy_room: easy_room, start_time: start_time, end_time: end_time)
      expect(conflict_meeting.valid?).to eq(false)
      expect(conflict_meeting.errors.full_messages.join).to include(meeting.name)

      conflict_meeting = FactoryBot.build(:easy_meeting, user_ids: [User.current.id], easy_room: easy_room, start_time: start_time + 1.minute, end_time: start_time + 1.minute)
      expect(conflict_meeting.valid?).to eq(false)

      conflict_meeting = FactoryBot.build(:easy_meeting, user_ids: [User.current.id], easy_room: easy_room, start_time: start_time - 1.minute, end_time: start_time + 1.minute)
      expect(conflict_meeting.valid?).to eq(false)

      valid_meeting = FactoryBot.build(:easy_meeting, user_ids: [User.current.id], easy_room: easy_room, start_time: start_time + 1.hour, end_time: end_time + 1.hour)
      expect(valid_meeting.valid?).to eq(true)

      valid_meeting2 = FactoryBot.build(:easy_meeting, user_ids: [User.current.id], easy_room: easy_room, start_time: start_time + 2.hours, end_time: end_time + 2.hours)
      expect(valid_meeting2.valid?).to eq(true)
    end

    it 'notifies author of repeated meeting when collision' do
      stub_const('EasyMeeting::CREATE_NOW_DAYS', 1)
      mail = double('mail')
      allow(mail).to receive(:deliver)
      reccuring = FactoryBot.build(:easy_meeting, :reccuring, :with_users, easy_room: easy_room, start_time: start_time - 1.day, end_time: end_time - 1.day)
      expect(EasyCalendarMailer).to receive(:easy_meeting_room_conflict).and_return(mail)
      reccuring.save
      meeting.validate_room_conflicts
      expect(meeting.errors).not_to be_empty
    end
  end

  describe '#visible?' do
    let(:user) { FactoryBot.create(:user) }

    context 'invited user' do
      context 'public meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xpublic, users: [user]) }

        it { expect(meeting.visible?(user)).to be_truthy }
      end

      context 'private meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xprivate, users: [user]) }

        it { expect(meeting.visible?(user)).to be_truthy }
      end

      context 'confidential meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :confidential, users: [user]) }

        it { expect(meeting.visible?(user)).to be_truthy }
      end
    end

    context 'user with view_all_meetings_detail permission' do
      before(:each) do
        allow(user).to receive(:allowed_to_globally?).with(:view_all_meetings_detail).and_return(true)
      end

      context 'public meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xpublic) }

        it { expect(meeting.visible?(user)).to be_truthy }
      end

      context 'private meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xprivate) }

        it { expect(meeting.visible?(user)).to be_truthy }
      end

      context 'confidential meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :confidential) }

        it { expect(meeting.visible?(user)).to be_falsey }
      end
    end

    context 'not invited user WITHOUT view_all_meetings_detail permission' do
      context 'public meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xpublic) }

        it { expect(meeting.visible?(user)).to be_truthy }
      end

      context 'private meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xprivate) }

        it { expect(meeting.visible?(user)).to be_truthy }
      end

      context 'confidential meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :confidential) }

        it { expect(meeting.visible?(user)).to be_falsey }
      end
    end

    context 'user is author' do
      context 'public meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xpublic, author: user) }

        it { expect(meeting.visible?(user)).to be_truthy }
      end

      context 'private meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xprivate, author: user) }

        it { expect(meeting.visible?(user)).to be_truthy }
      end

      context 'confidential meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :confidential, author: user) }

        it { expect(meeting.visible?(user)).to be_truthy }
      end
    end
  end

  describe '#visible_details?' do
    let(:user) { FactoryBot.create(:user) }

    context 'invited user' do
      context 'public meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xpublic, users: [user]) }

        it { expect(meeting.visible_details?(user)).to be_truthy }
      end

      context 'private meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xprivate, users: [user]) }

        it { expect(meeting.visible_details?(user)).to be_truthy }
      end

      context 'confidential meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :confidential, users: [user]) }

        it { expect(meeting.visible_details?(user)).to be_truthy }
      end
    end

    context 'user with view_all_meetings_detail permission' do
      before(:each) do
        allow(user).to receive(:allowed_to_globally?).with(:view_all_meetings_detail).and_return(true)
      end

      context 'public meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xpublic) }

        it { expect(meeting.visible_details?(user)).to be_truthy }
      end

      context 'private meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xprivate) }

        it { expect(meeting.visible_details?(user)).to be_truthy }
      end

      context 'confidential meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :confidential) }

        it { expect(meeting.visible_details?(user)).to be_falsey }
      end
    end

    context 'not invited user WITHOUT view_all_meetings_detail permission' do
      context 'public meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xpublic) }

        it { expect(meeting.visible_details?(user)).to be_truthy }
      end

      context 'private meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xprivate) }

        it { expect(meeting.visible_details?(user)).to be_falsey }
      end

      context 'confidential meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :confidential) }

        it { expect(meeting.visible_details?(user)).to be_falsey }
      end
    end

    context 'user is author' do
      context 'public meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xpublic, author: user) }

        it { expect(meeting.visible_details?(user)).to be_truthy }
      end

      context 'private meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :xprivate, author: user) }

        it { expect(meeting.visible_details?(user)).to be_truthy }
      end

      context 'confidential meeting' do
        let(:meeting) { FactoryBot.create(:easy_meeting, privacy: :confidential, author: user) }

        it { expect(meeting.visible_details?(user)).to be_truthy }
      end
    end
  end

  context 'easy meeting notifier' do
    let(:upcoming_meeting) { FactoryBot.create(:easy_meeting, :with_users, start_time: Time.now + 1.day) }
    let(:future_meeting) { FactoryBot.create(:easy_meeting, :with_users, start_time: Time.now + 10.day) }

    let(:upcoming_meeting_1) { FactoryBot.create(:easy_meeting, :with_users, start_time: Time.now + 1.day, email_notifications: :right_now) }
    let(:future_meeting_1) { FactoryBot.create(:easy_meeting, :with_users, start_time: Time.now + 10.day, email_notifications: :right_now) }

    subject(:notifier) { -> { EasyRakeTaskEasyMeetingNotifier.new.execute } }

    it 'default email settings: one_week_before' do
      # upcoming event should be notified immediately
      expect { upcoming_meeting }.to change { EasyCalendarMailer.deliveries.count }.by(2)
      expect { subject.call }.to_not change { EasyCalendarMailer.deliveries.count }

      # future event should be notified by notifier
      expect { future_meeting }.to_not change { EasyCalendarMailer.deliveries.count }
      with_time_travel(3.days) do
        expect { subject.call }.to change { EasyCalendarMailer.deliveries.count }.by(2)
      end
    end

    it 'right_now' do
      # upcoming event should be notified immediately
      expect { upcoming_meeting_1 }.to change { EasyCalendarMailer.deliveries.count }.by(2)
      expect { subject.call }.to_not change { EasyCalendarMailer.deliveries.count }

      # future event should be notified immediately
      expect { future_meeting_1 }.to change { EasyCalendarMailer.deliveries.count }.by(2)
      with_time_travel(3.days) do
        expect { subject.call }.to_not change { EasyCalendarMailer.deliveries.count }
      end
    end
  end

  context 'easy meeting notification' do
    let(:old_meeting) { FactoryBot.create(:easy_meeting, start_time: Time.now - 1.day, email_notifications: :right_now) }

    it 'update old' do
      expect(old_meeting).not_to receive(:notify_invitees)
      old_meeting.update(name: 'test old')
    end
  end

end
