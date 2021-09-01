FactoryBot.define do

  factory :last_comments_journal, class: "Journal" do
    sequence(:notes) { |n| "Notes #{n}" }
  end

end
