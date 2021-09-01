class EasyJenkins::PipelinesIssueStatus < ActiveRecord::Base
  self.table_name = 'easy_jenkins_pipelines_issue_statuses'

  belongs_to :pipeline, class_name: 'EasyJenkins::Pipeline'
  belongs_to :issue_status
end
