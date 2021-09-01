# Use this module for static methods
module EasyResourceBase

  def self.reschedule_issues(all_issues, days)
    all_resources = EasyGanttResource.where(issue_id: all_issues)

    min, max = all_resources.pluck(Arel.sql('MIN(date), MAX(date)')).first
    if min.nil? || max.nil?
      return
    end

    diff = (max - min).to_i + 1

    # User is shifting date for a little bit - will raise `ActiveRecord::RecordNotUnique`
    #   | 8 | 8 | 8 |
    #       | 8 | 8 | 8 |
    #         ^--- there already exist
    if days < diff
      all_resources.update_all("date = date + INTERVAL '#{diff}' DAY")
      days = days-diff
    end

    all_resources.update_all("date = date + INTERVAL '#{days}' DAY")
  end

end
