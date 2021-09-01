class EasyJenkins::PipelinesIssue < ActiveRecord::Base
  self.table_name = 'easy_jenkins_pipelines_issues'

  belongs_to :pipeline, class_name: 'EasyJenkins::Pipeline'
  belongs_to :issue
end
