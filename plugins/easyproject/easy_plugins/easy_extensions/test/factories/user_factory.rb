FactoryBot.define do
  factory :user, aliases: [:author] do
    firstname { 'John' }
    sequence(:lastname) { |n| 'Doe' + n.to_s }
    login { "#{firstname}-#{lastname}".downcase }
    sequence(:mail) { |n| "user#{n}@test.com" }
    admin { false }
    language { 'en' }
    status { 1 }
    mail_notification { 'only_my_events' }
    password { 'ValidPassword1.' }

    # easy_user_type_id 1

    after(:create) do |user, evaluator|
      pref                                   = user.pref
      pref.last_easy_attendance_arrival_date = user.today
      pref.save
    end

    trait :admin do
      firstname { 'Admin' }
      admin { true }
    end

    factory :admin_user, :traits => [:admin]

  end

end
