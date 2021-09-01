FactoryGirl.define do
  factory :easy_icalendar do
    user { User.current }
    sequence(:name) { |n| "iCal #{n}" }
    sequence(:url) { |n| "https://ical_url/#{n}" }

    after(:build) { |ical| ical.class.skip_callback(:commit, :after, :import_events) }

    factory :ical_with_import do
      after(:create) { |ical| ical.send(:import_events) }
    end
  end
end
