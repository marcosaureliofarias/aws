FactoryBot.define do
  factory :re_relationtype do
    project
    relation_type { 'parentchild' }
    alias_name { 'parentchild name' }
    color { '#111111' }
    is_system_relation { 1 }
    is_directed { 1 }
    in_use { 1 }
  end
end