FactoryBot.define do
  factory :easy_to_do_list do
    user
    sequence(:name) { |n| "TODO ##{n}" }
    #position
  end

  factory :easy_to_do_list_item do
    easy_to_do_list
    sequence(:name) { |n| "TODO item ##{n}" }
    is_done { false }
    #position
    #entity
  end
end
