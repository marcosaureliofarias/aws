require 'rys'

require 'show_last_comments_on_issue/engine'

module ShowLastCommentsOnIssue
  def self.show_settings?
    Rys::Feature.active?('show_last_comments_on_issue.show') || Rys::Feature.active?('show_last_comments_on_issue.index')
  end
end
