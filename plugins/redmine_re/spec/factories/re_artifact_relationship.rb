FactoryBot.define do
  factory :re_artifact_relationship do
    association :source, factory: :re_artifact_properties
    association :sink, factory: :re_artifact_properties
    relation_type { 'parentchild' }
  end
end