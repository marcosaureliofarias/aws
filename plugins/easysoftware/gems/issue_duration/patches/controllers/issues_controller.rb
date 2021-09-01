Rys::Patcher.add('IssuesController') do

  apply_if_plugins :easy_extensions

  instance_methods(feature: 'issue_duration') do

    def build_new_issue_from_params
      if super && (issue_params = params[:issue]) && issue_params[:easy_duration].present?
        @issue.easy_duration = IssueEasyDuration.easy_duration_days_count(issue_params[:easy_duration].to_i, issue_params[:easy_duration_time_unit])
      end
    end

  end

end
