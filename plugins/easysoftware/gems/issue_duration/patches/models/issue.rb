Rys::Patcher.add('Issue') do

  apply_if_plugins :easy_extensions

  included do
    attr_accessor :easy_duration_time_unit

    safe_attributes 'easy_duration', 'easy_duration_time_unit'

    validates_numericality_of :easy_duration, greater_than_or_equal_to: 1, allow_nil: true

    before_save :set_easy_duration, if: -> { will_save_change_to_start_date? || will_save_change_to_due_date? }

    def set_easy_duration
      if [start_date, due_date].any? &:blank?
        self.easy_duration = nil
      else
        self.easy_duration = IssueEasyDuration.easy_duration_calculate(start_date, due_date)
      end
    end
  end

end
