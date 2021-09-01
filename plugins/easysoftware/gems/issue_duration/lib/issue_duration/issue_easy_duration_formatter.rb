module IssueDuration
  module IssueEasyDurationFormatter

    def self.easy_duration_formatted(unformatted_value, easy_duration_unit, value_for_nil = '')
      if unformatted_value.present?
        "#{unformatted_value} #{I18n.t("issue_duration.time_units.#{easy_duration_unit}")}"
      else
        value_for_nil
      end
    end

    # Feature
    #
    # def issue_easy_duration_formatter(duration)
    #   if duration % 7 == 0
    #     formatted_value = formatted_value(duration / 7, 'week')
    #   elsif duration % 30 == 0
    #     formatted_value = formatted_value(duration / 30, 'month')
    #   else
    #     formatted_value = formatted_value(duration, 'day')
    #   end
    #   formatted_value
    # end
    #
    # def formatted_value(duration, unit)
    #   "#{duration} #{l("issue_duration.time_units.#{unit}")}"
    # end

  end
end

