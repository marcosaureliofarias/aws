FactoryBot.define do

  factory :group do
    sequence(:lastname) {|n| "Group ##{n}"}
    status { Principal::STATUS_ACTIVE }
    admin { false }
    type { "Group" }
  end
  
end
