module EasyPatch
  module UserPreferencePatch

    def self.included(base)
      base.class_eval do
        base.include(InstanceMethods)

        alias_method_chain :initialize, :easy_extensions

        safe_attributes 'no_notification_ever',
                        'number_alignment',
                        'user_theme',
                        'disable_automatic_loading',
                        'no_notified_if_issue_closing',
                        'no_notified_as_previous_assignee',
                        'last_easy_attendance_arrival_date',
                        'last_easy_attendance',
                        'display_journal_details',
                        'global_time_entries_visibility',
                        'hide_notification_passwd_expiration',
                        'user_time_entry_setting',
                        'hours_format'

        def no_notified_if_issue_closing
          self[:no_notified_if_issue_closing].to_boolean
        end

        def no_notified_if_issue_closing=(value)
          self[:no_notified_if_issue_closing] = value
        end

        def no_notified_as_previous_assignee
          self[:no_notified_as_previous_assignee].to_boolean
        end

        def no_notified_as_previous_assignee=(value)
          self[:no_notified_as_previous_assignee] = value
        end

        def no_notification_ever
          self[:no_notification_ever].to_boolean
        end

        def no_notification_ever=(value)
          self[:no_notification_ever] = value
        end

        def number_alignment;
          self[:number_alignment] || '0'
        end

        def number_alignment=(value)
          self[:number_alignment] = value
        end

        def user_theme
          self[:user_theme]
        end

        def user_theme=(value)
          self[:user_theme] = value
        end

        def disable_automatic_loading
          self[:disable_automatic_loading].to_s.to_boolean
        end

        def disable_automatic_loading=(value)
          self[:disable_automatic_loading] = value
        end

        def last_easy_attendance_arrival_date
          self[:last_easy_attendance_arrival_date]
        end

        def last_easy_attendance_arrival_date=(value)
          self[:last_easy_attendance_arrival_date] = value
        end

        def last_easy_attendance_user_ip
          self[:last_easy_attendance_user_ip]
        end

        def last_easy_attendance_user_ip=(value)
          self[:last_easy_attendance_user_ip] = value
        end

        def display_journal_details
          # if self[:display_journal_details].present?
          #   self[:display_journal_details] == true || self[:display_journal_details] == '1'
          # else
          #   EasySetting.value('display_journal_details')
          # end

          true
        end

        def display_journal_details=(value)
          self[:display_journal_details] = value
        end

        def global_time_entries_visibility
          self[:global_time_entries_visibility].to_s.to_boolean
        end

        def global_time_entries_visibility=(value)
          self[:global_time_entries_visibility] = value
        end

        def hide_notification_passwd_expiration
          self[:hide_notification_passwd_expiration].to_s.to_boolean
        end

        def hide_notification_passwd_expiration=(value)
          self[:hide_notification_passwd_expiration] = value
        end

      end
    end

    module InstanceMethods

      def initialize_with_easy_extensions(attributes=nil, *args)
        initialize_without_easy_extensions(attributes, *args)
        if new_record?
          unless attributes && attributes.key?(:no_notified_as_previous_assignee)
            self.no_notified_as_previous_assignee = EasySetting.value('default_no_notified_as_previous_assignee')
          end
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'UserPreference', 'EasyPatch::UserPreferencePatch'
