FactoryGirl.define do
  factory :easy_invitation do
    association :user, :firstname => "Invited"
    association :easy_meeting
  end
end
