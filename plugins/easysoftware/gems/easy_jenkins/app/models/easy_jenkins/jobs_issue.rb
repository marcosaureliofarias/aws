class EasyJenkins::JobsIssue < ApplicationRecord
  self.table_name = 'easy_jenkins_jobs_issues'

  belongs_to :job, class_name: 'EasyJenkins::Job', foreign_key: 'easy_jenkins_job_id'
  belongs_to :issue, touch: false
end