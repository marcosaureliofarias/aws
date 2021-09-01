FactoryBot.define do

  factory :user, aliases: [:author] do
    sequence(:firstname) { |n| "Firstname#{n}" }
    sequence(:lastname) { |n| "Lastname#{n}" }
    sequence(:mail) { |n| "user#{n}@example.net" }
    login { "#{firstname}-#{lastname}".downcase }
    status { Principal::STATUS_ACTIVE }
    admin { false }
    language { 'en' }
    mail_notification { 'only_my_events' }

    trait :admin do
      admin { true }
    end
  end

end
