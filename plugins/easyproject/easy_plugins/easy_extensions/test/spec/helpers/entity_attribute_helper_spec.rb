require 'easy_extensions/spec_helper'

describe EntityAttributeHelper do
  context '#format_easy_entity_activity_attendees' do
    it 'disabled user' do
      disabled_user = EasyDisabledPrincipal.new
      attendee      = EasyEntityActivityAttendee.new(entity: disabled_user)
      expect(helper.send(:format_easy_entity_activity_attendees, attendee, {})).to eq('-')
    end

    it 'anonym' do
      attendee = EasyEntityActivityAttendee.new(entity: User.current)
      expect(helper.send(:format_easy_entity_activity_attendees, attendee, {})).to include(User.current.name)
    end
  end
end


