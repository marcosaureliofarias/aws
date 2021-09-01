class EasyAgileBacklogRelation < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :issue

  acts_as_positioned scope: :project_id

  before_save :ensure_new_position

  attr_accessor :new_position

  safe_attributes :project_id, :issue_id, :new_position

  # def self.assign_issue(issue, project, row_position = nil)
  #   issue = Issue.find(issue) unless issue.is_a?(Issue)
  #   return issue.errors.add(:base, l(:error_assign_closed_issues_to_project_backlog)) if issue.closed?
  #
  #   issue.update(:easy_sprint => nil) if issue.easy_sprint.present?
  #
  #   if assignment = EasyAgileBacklogRelation.where(:issue_id => issue).first
  #     assignment.project = project
  #   else
  #     assignment = project.easy_agile_backlog_relations.build(:issue => issue)
  #   end
  #
  #   assignment.issue = issue
  #   assignment.new_position = row_position
  #   assignment.save
  # end

  private

  def ensure_new_position
    return if self.new_position.blank?
    new_new_position = self.new_position
    self.new_position = nil
    self.position = new_new_position.to_i
  end

end
