class EasyJenkins::Pipeline < ActiveRecord::Base
  self.table_name = 'easy_jenkins_pipelines'

  belongs_to :setting, class_name: 'EasyJenkins::Setting', foreign_key: 'easy_jenkins_setting_id'

  has_many :jobs, class_name: 'EasyJenkins::Job', dependent: :destroy, foreign_key: 'easy_jenkins_pipeline_id'
  has_many :pipelines_issues,   class_name: 'EasyJenkins::PipelinesIssue', dependent: :destroy, foreign_key: 'easy_jenkins_pipeline_id'
  has_many :pipelines_trackers, class_name: 'EasyJenkins::PipelinesTracker', dependent: :destroy, foreign_key: 'easy_jenkins_pipeline_id'
  has_many :pipelines_statuses, class_name: 'EasyJenkins::PipelinesIssueStatus', dependent: :destroy, foreign_key: 'easy_jenkins_pipeline_id'

  has_many :issues, through: :pipelines_issues
  has_many :trackers, through: :pipelines_trackers
  has_many :statuses, through: :pipelines_statuses, source: :issue_status

  if Redmine::Plugin.installed?(:redmine_test_cases)
    has_many :test_cases, dependent: :nullify
  end

  scope :for_issue,     ->(issue, project) { left_outer_joins(:issues).joins(:setting).where(issues: { id: issue.id }).or(for_all_tasks(project).left_outer_joins(:issues)) }
  scope :for_status,    ->(status)  { joins(:statuses).where('issue_statuses.id = ?', status.id) }
  scope :for_all_tasks, ->(project) { joins(:setting).where(for_all_tasks: true, easy_jenkins_settings: { project_id: project.id }) }

  def to_s
    external_name
  end

  # def self.jobs_for_issue(issue)
  #   EasyJenkins::Job.where(easy_jenkins_pipeline_id: for_issue(issue, issue.project)).distinct.ordered
  # end
end
