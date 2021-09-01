module EasyPatch
  module SettingsHelperPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        alias_method_chain :administration_settings_tabs, :easy_extensions
        alias_method_chain :notification_field, :easy_extensions
        alias_method_chain :setting_check_box, :easy_extensions
        alias_method_chain :setting_label, :easy_extensions
        alias_method_chain :session_lifetime_options, :easy_extensions
        alias_method_chain :session_timeout_options, :easy_extensions

        def notification_grid(notifiables)
          groups = notifiables.group_by(&:parent)

          groups.clone.each do |k, v|
            parent         = groups[nil].detect { |e| e.name == k }
            groups[parent] = groups.delete(k)
            groups[nil].delete(parent)
          end

          groups
        end
      end
    end

    module InstanceMethods

      def administration_settings_tabs_with_easy_extensions
        [{ :name => 'general', :partial => 'settings/general', :label => :label_general },
         { :name => 'display', :partial => 'settings/display', :label => :label_display },
         { :name => 'authentication', :partial => 'settings/authentication', :label => :label_authentication },
         { :name => 'api', :partial => 'settings/api', :label => :label_api },
         { :name => 'projects', :partial => 'settings/projects', :label => :label_project_plural },
         { :name => 'users', :partial => 'settings/users', :label => :label_user_plural },
         { :name => 'issues', :partial => 'settings/issues', :label => :label_issue_tracking },
         { :name => 'timeentries', :partial => 'settings/timeentries', :label => :label_time_tracking },
         { :name => 'attachments', :partial => 'settings/attachments', :label => :label_attachment_plural },
         { :name => 'notifications', :partial => 'settings/notifications', :label => :field_mail_notification },
         { :name => 'mail_handler', :partial => 'settings/mail_handler', :label => :label_incoming_emails },
         { :name => 'repositories', :partial => 'settings/repositories', :label => :label_repository_plural }
        ]
      end

      def setting_check_box_with_easy_extensions(setting, options = {})
        box = check_box_tag("settings[#{setting}]", 1, Setting.send("#{setting}?"), options).html_safe
        hidden_field_tag("settings[#{setting}]", 0, :id => nil).html_safe +
            setting_label(setting, options.merge(:input => box, :label_options => { :class => 'inline checkbox' })).html_safe
      end

      def setting_label_with_easy_extensions(setting, options = {})
        label = options.delete(:label)
        input = options.delete(:input)
        if label == false
          input ? input : ''
        else
          text = label.is_a?(String) ? label : l(label || "setting_#{setting}")
          unless input.nil? || input == false
            label_tag("settings_#{setting}", input + text, options[:label_options])
          else
            label_tag("settings_#{setting}", text, options[:label_options])
          end
        end
      end

      def notification_field_with_easy_extensions(notifiable)
        tag_data = notifiable.parent.present? ?
                       { :parent_notifiable => notifiable.parent } :
                       { :disables => "input[data-parent-notifiable=#{notifiable.name}]" }

        tag = check_box_tag('settings[notified_events][]',
                            notifiable.name,
                            Setting.notified_events.include?(notifiable.name),
                            :id   => nil,
                            :data => tag_data)

        text = l_or_humanize(notifiable.name, :prefix => 'label_')

        options         = {}
        options[:class] = "checkbox inline"
        if notifiable.parent.present?
          options[:class] << " parent"
        end

        content_tag(:label, tag + text, options)
      end

      def session_lifetime_options_with_easy_extensions
        options = session_lifetime_options_without_easy_extensions
        [2, 1].each do |hours|
          options.insert(1, [l('datetime.distance_in_words.x_hours', count: hours), (hours * 60).to_s])
        end
        options
      end

      def session_timeout_options_with_easy_extensions
        options = session_timeout_options_without_easy_extensions
        [45, 30, 15].each do |minutes|
          options.insert(1, [l('datetime.distance_in_words.x_minutes', count: minutes), minutes.to_s])
        end
        options
      end
    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'SettingsHelper', 'EasyPatch::SettingsHelperPatch'
