FactoryGirl.define do
  factory :easy_user_type do
    sequence(:name) { |n| 'test_easy_user_type' + n.to_s }
    is_default { false }
    internal { true }

    factory :test_easy_user_type

  end

end
