FactoryBot.define do
  factory :diagram do
    project
    title { 'Title' }
  end

  factory :diagram_version do
    diagram
    position { 1 }
  end
end