class AddEasyLastUpdatedByToIssues < ActiveRecord::Migration[4.2]
  def up
    updators_by_issues      = Hash.new { |mem, key| mem[key] = [] }
    last_issues_by_updators = Hash.new { |mem, key| mem[key] = [] }

    Journal.joins(:issue).where(:journalized_type => 'Issue').order(:id).pluck(:id, :user_id, :journalized_id).
        each { |id, user_id, issue_id| updators_by_issues[issue_id] << user_id }

    updators_by_issues.each do |issue_id, user_ids|
      author_id = user_ids.last
      last_issues_by_updators[author_id] << issue_id
    end

    last_issues_by_updators.each do |user_id, issue_ids|
      Issue.where(id: issue_ids).update_all(easy_last_updated_by_id: user_id)
    end

    Issue.where(:easy_last_updated_by_id => nil).update_all("easy_last_updated_by_id = author_id")
  end

  def down
  end

end
