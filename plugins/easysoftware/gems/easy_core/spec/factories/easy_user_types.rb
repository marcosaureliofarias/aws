FactoryBot.define do

  factory :easy_user_type do
    sequence(:name) { |n| ( "User type ##{n}").humanize }

    is_default { !EasyUserType.any? }

    trait :internal do
      internal { true }
      settings do
        %i[home_icon projects issues more custom_menu before_search search jump_to_project administration sign_out user_profile]
      end
    end
  end
end
