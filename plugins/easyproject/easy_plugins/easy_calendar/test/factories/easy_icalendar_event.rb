FactoryGirl.define do
  factory :easy_icalendar_event do
    easy_icalendar
    sequence(:summary) { |n| "iCal event #{n}" }
    sequence(:uid) { |n| "ical_event_#{n}" }
    dtstart { Time.now + Random.rand(40).hours }
    dtend { dtstart + (1 + Random.rand(3)).hours }
  end
end
