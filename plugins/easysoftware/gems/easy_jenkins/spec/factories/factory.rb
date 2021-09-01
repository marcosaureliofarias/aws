FactoryBot.define do

  factory :pipeline, class: EasyJenkins::Pipeline do
    external_name { 'Title' }
  end

  factory :easy_jenkins_job, class: EasyJenkins::Job do
    state { :pending }
    queue_id { 1 }
    association :pipeline, factory: :pipeline
  end

  factory :easy_jenkins_setting, class: EasyJenkins::Setting do
    url { 'url' }
    user_name { 'user_name' }
    user_token { 'user_token' }
    association :project, factory: :project
  end

end