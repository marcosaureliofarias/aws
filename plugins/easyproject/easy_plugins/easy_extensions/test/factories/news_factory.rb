# encoding: utf-8
FactoryGirl.define do
  factory :news do
    project
    sequence(:title) { |n| 'Blesk ' + n.to_s }
    summary { 'Lorem Ipsum is simply dummy text' }
    description { 'Lorem Ipsum is simply dummy text of the printing and typesetting industry.' }
    author
  end

  factory :comment do
    association :commented, factory: :news
    author
    comments { 'Becherovka je příjemný požitek, ať už v deset ráno, nebo pozdě večer.' }
  end

end
