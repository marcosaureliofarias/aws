Rys::Patcher.add('EntityAttributeHelper') do

  apply_if_plugins :easy_extensions

  included do

    def format_issue_attribute_with_issue_easy_duration(entity_class, attribute, unformatted_value, options = {})
      if attribute.name == :easy_duration
        IssueDuration::IssueEasyDurationFormatter.easy_duration_formatted(unformatted_value, 'day')
      else
        format_issue_attribute_without_issue_easy_duration(entity_class, attribute, unformatted_value, options)
      end
    end

    alias_method_chain :format_issue_attribute, :issue_easy_duration

  end

end

