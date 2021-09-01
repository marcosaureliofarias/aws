require 'easy_extensions/spec_helper'

describe EasyEntityActivityQuery, type: :model do

  let(:users) { FactoryBot.create_list(:user, 2) }
  let(:issue) { FactoryBot.create(:issue) }
  let(:entity_activity) { EasyEntityActivity.create(entity_type: 'Issue', entity_id: issue.id) }

  it 'objects for easy_entity_activity_attendees' do
    users
    instance = described_class.new
    users.each do |u|
      EasyEntityActivityAttendee.create(entity_type: 'Principal', entity_id: u.id, easy_entity_activity_id: entity_activity.id)
    end
    filter_values = users.map { |u| "Principal_#{u.id}" }
    short_filter = "=#{filter_values.join('|')}"
    instance.add_short_filter('easy_entity_activity_attendees', short_filter)
    objects = instance.send(:objects_for, 'easy_entity_activity_attendees')
    expect(objects.map(&:to_s)).to match_array(users.map(&:to_s))
    expect(objects.map(&:id)).to match_array(filter_values)
  end

end