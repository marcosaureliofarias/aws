FactoryBot.define do

  factory :journal do
    sequence(:notes) { |n| "Notes #{n}" }
  end

end
