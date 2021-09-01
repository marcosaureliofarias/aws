class EasyJenkins::Job < ActiveRecord::Base
  self.table_name = 'easy_jenkins_jobs'

  belongs_to :pipeline, class_name: 'EasyJenkins::Pipeline', foreign_key: 'easy_jenkins_pipeline_id'

  has_many :jobs_issues, class_name: 'EasyJenkins::JobsIssue', dependent: :destroy, foreign_key: 'easy_jenkins_job_id'
  has_many :issues, through: :jobs_issues

  enum state: { pending: 0, failure: 1, success: 2 }

  scope :ordered,   -> { order(created_at: :desc) }
  scope :for_issue, ->(issue) { joins(:issues).where(issues: { id: issue.id }) }

  delegate :external_name, to: :pipeline, allow_nil: true

  def to_s
    if pending?
      I18n.t('easy_jenkins.pipeline_pending_result', name: external_name)
    else
      I18n.t('easy_jenkins.pipeline_finished_result', name: external_name, duration: duration_to_s)
    end
  end

  def timestamp_to_s
    "#{created_at.to_date} (#{duration_to_s})"
  end

  def duration_to_s
    duration.present? ? "#{duration_to_seconds}s" : state
  end

  def duration_to_seconds
    (duration / 1000).round(1)
  end

  def icon_css_class
    if pending?
      'button-2 icon-timer'
    elsif failure?
      'button-3 icon-error'
    else
      'button-positive icon-checked'
    end
  end

  def update_test_cases
    tce_pass = TestCaseIssueExecutionResult.find_by(name: 'Pass')
    tce_fail = TestCaseIssueExecutionResult.find_by(name: 'Fail')

    # get connected test cases from related issues
    issues.joins(project: [:enabled_modules]).where("enabled_modules.name = 'test_cases'").each do |issue|
      test_cases = issue.collect_test_cases.delete_if { |test_case| !test_case.automated? || test_case.easy_jenkins_pipeline_id != easy_jenkins_pipeline_id }
      test_cases.each do |test_case|
        test_case.test_case_issue_executions.create!(
          author: test_case.author,
          issue: issue,
          result_id: success? ? tce_pass.id : tce_fail.id,
          comments: result
        )
      end
    end
  end
end