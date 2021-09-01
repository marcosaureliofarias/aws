class EasyCrmCaseMailTemplate < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :easy_crm_case_status

  validates :project, :presence => true
  validates :subject, :presence => true

  html_fragment :body_html, :scrub => :strip
  html_fragment :body_plain, :scrub => :strip

  safe_attributes 'project_id', 'easy_crm_case_status_id', 'subject', 'body_html', 'body_plain'

  def self.find_all_for_easy_crm_case(easy_crm_case)
    where(:project_id => easy_crm_case.project_id)
  end

  def caption
    return @caption if @caption

    @caption = ''
    @caption << "(#{self.easy_crm_case_status.name}) - " if self.easy_crm_case_status
    @caption << self.subject

    @caption
  end

end
