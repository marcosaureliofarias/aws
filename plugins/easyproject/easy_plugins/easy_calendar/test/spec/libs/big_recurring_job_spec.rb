require 'easy_extensions/spec_helper'

RSpec.describe EasyCalendar::BigRecurringJob do

  let(:big_recurring_meeting) {
    FactoryBot.create(:easy_meeting,
                      start_time: Time.now,
                      easy_is_repeating: true,
                      big_recurring: true,
                      easy_repeat_settings: {
                        'period'          => 'daily',
                        'daily_option'    => 'each',
                        'daily_each_x'    => '1',
                        'endtype'         => 'count',
                        'endtype_count_x' => '1',
                      })
  }
  let(:big_recurring_meeting_child) {
    FactoryBot.create(:easy_meeting,
                      start_time: big_recurring_meeting.start_time,
                      easy_repeat_parent_id: big_recurring_meeting.id)
  }
  let(:new_invitee) { FactoryBot.create(:user) }

  subject { described_class.new }

  describe '#perform' do
    context 'vue modal - sending only changed attributes' do
      context 'state update_all, changed user_ids' do
        it 'changes child invitees' do
          big_recurring_meeting_child
          big_recurring_meeting.safe_attributes = { user_ids: [new_invitee.id] }
          big_recurring_meeting.save

          subject.perform(big_recurring_meeting, [:update_all].map(&:to_s), ['user_ids'])

          expect(big_recurring_meeting.easy_repeat_children.first.users).to contain_exactly(new_invitee)
        end
      end
    end
  end

end
