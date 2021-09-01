Rys::Patcher.add('IssuesHelper') do

  apply_if_plugins :easy_extensions

  included do

    def issue_easy_duration_formatter(duration)
      IssueDuration::IssueEasyDurationFormatter.easy_duration_formatted(duration, 'day', '---')
    end

  end

end
