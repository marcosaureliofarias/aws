FactoryBot.define do
  factory :easy_data_template do
    sequence(:name) { |n| "T ##{n}" }
    association :author, factory: :user
    template_type { 'import' }
    format_type { 'xml' }
  end

  factory :easy_data_template_ms_project, parent: :easy_data_template, class: 'EasyDataTemplateMsProject' do
    type { 'EasyDataTemplateMsProject' }
  end
end
