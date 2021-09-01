FactoryGirl.define do
  factory :easy_user_target do
    user
    target { 1 }
    valid_from { Date.today }
    valid_to { Date.today }
    currency { 'czk' }
  end
end
