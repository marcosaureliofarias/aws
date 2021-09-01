FactoryBot.define do

  factory :news do
    project
    sequence(:title) {|n| 'News #' + n.to_s }
    summary { 'Lorem Ipsum is simply dummy text' }
    description { 'Lorem Ipsum is simply dummy text of the printing and typesetting industry.' }
    author
  end

end
