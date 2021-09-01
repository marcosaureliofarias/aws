module EasyCalendar
  class BigRecurringJob < EasyActiveJob

    def perform(easy_meeting, change_state, attrs_changed)
      log_info "EasyMeeting ID=#{easy_meeting.id}"
      log_info "ChangeState #{change_state}"
      log_info "AttrsChanged #{attrs_changed}"

      # Delete all children
      if change_state.include?("delete_all")
        easy_meeting.easy_repeat_children.destroy_all
      end

      # Reset counter so it could be repeated again
      if change_state.include?("reset_counter")
        start_on = easy_meeting.start_time.to_date

        easy_meeting.easy_repeat_settings.delete('repeated')
        easy_meeting.easy_repeat_settings['start_timepoint'] = start_on

        easy_meeting.update_columns(easy_repeat_settings: easy_meeting.easy_repeat_settings,
                                    easy_next_start: easy_meeting.count_next_start(start_on, true))
      end

      # Create all repeating
      if change_state.include?("create_all")
        # Otherwise it will cycle
        _create_now = easy_meeting.easy_repeat_settings.delete('create_now')

        EasyMeeting::MAX_BIG_RECURRING_COUNT.times do |i|
          log_info "Create recurring: #{i}"

          date = easy_meeting.easy_next_start || Date.today
          if easy_meeting.should_repeat?(date)
            easy_meeting.repeat
          else
            break
          end
        end

        # easy_meeting.easy_repeat_settings['create_now']
      end

      # Update all children based on parent
      if change_state.include?("update_all") && attrs_changed&.any?
        attributes = easy_meeting.attributes.select { |k, _| attrs_changed.include?(k) }

        easy_meeting.easy_repeat_children.each do |child|
          log_info "Update recurring: ##{child.id}"

          child.attributes = attributes
          child.users = easy_meeting.users if attrs_changed.include?('user_ids')
          child.save(validate: false)
        end
      end

    end

  end
end
