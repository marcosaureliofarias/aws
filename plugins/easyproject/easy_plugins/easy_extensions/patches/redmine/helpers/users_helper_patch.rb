module EasyPatch
  module UsersHelperPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :user_settings_tabs, :easy_extensions

        def user_show_tabs
          tabs = [{ :name => 'general_show', :partial => 'users/show', :label => :label_general, :no_js_link => true }]
          call_hook(:helper_user_show_tabs, :user => @user, :tabs => tabs)
          tabs
        end

        def easy_user_type_options
          EasyUserType.sorted.collect { |t| [t.name, t.id.to_s] }
        end

        def easy_lesser_admin_permissions
          list = [
              [l(:label_admin_easy_user_working_time_calendars), :working_time],
              [l(:label_custom_field_plural), :custom_fields],
              [l(:label_easy_broadcasts), :easy_broadcasts],
              [l(:label_easy_query_settings), :easy_query_settings],
              [l(:label_easy_pages_project_administration), :easy_pages_administration],
              [l(:label_group_plural), :groups],
              [l(:label_issue_status_plural), :issue_statuses],
              [l(:label_role_and_permissions), :roles],
              [l(:label_tracker_plural), :trackers],
              [l(:label_user_plural), :users],
              [l(:label_workflow), :workflows],
              [l(:label_easy_user_type_plural), :easy_user_types]
          ]

          ctx = { list: list }
          Redmine::Hook.call_hook(:helper_users_easy_lesser_admin_permissions, ctx)

          ctx[:list]
        end

        def user_profile_menu_item_user_profile
          user_path(@user)
        end

        def user_profile_menu_item_assigned_issues
          { :controller => 'issues', :set_filter => 1, :assigned_to_id => @user.id, :status_id => 'o' }
        end

        def user_profile_menu_item_assigned_issues_after_due_date
          { :controller => 'issues', :set_filter => 1, :assigned_to_id => @user.id, :due_date => 'after_due_date', :status_id => 'o' }
        end

        def user_profile_menu_item_assigned_issues_not_updated
          { :controller => 'issues', :set_filter => 1, :assigned_to_id => @user.id, :not_updated_on => '7_days', :status_id => 'o' }
        end

        def user_profile_menu_item_new_issue
          { :controller => 'issues', :action => 'new', :'issue[assigned_to_id]' => @user.id }
        end

        def user_profile_menu_item_time_entries
          easy_time_entries_path(:set_filter => '1', :user_id => @user.id, :spent_on => 'current_month')
        end

        def user_profile_menu_item_easy_attendances_calendar
          { :controller => 'easy_attendances', :action => 'index', :tab => 'calendar', :user_id => @user.id, :set_filter => 1 }
        end

        def user_profile_menu_item_easy_attendances_list
          { :controller => 'easy_attendances', :action => 'index', :tab => 'list', :user_id => @user.id, :set_filter => 1 }
        end

        def user_profile_menu_item_easy_attendances_report
          { :controller => 'easy_attendances', :action => 'report', 'report[users][]' => @user.id, 'report[period_type]' => '1', 'report[period]' => 'current_month' }
        end

        def user_profile_menu_item_mail_to
          "mailto:#{@user.mail}" if @user
        end

        def info_password_notification
          must_include = []

          if EasySetting.value('passwd_constrains_big_letter')
            must_include << l('label_password_must_include.big_letter')
          end
          if EasySetting.value('passwd_constrains_small_letter')
            must_include << l('label_password_must_include.small_letter')
          end
          if EasySetting.value('passwd_constrains_number')
            must_include << l('label_password_must_include.number')
          end
          if EasySetting.value('passwd_constrains_special_character')
            must_include << l('label_password_must_include.special_character')
          end

          must_include.empty? ? '' : "#{l('label_password_must_include.title')}: #{must_include.join(', ')}."
        end

      end
    end

    module InstanceMethods

      def user_settings_tabs_with_easy_extensions
        tabs = [{ :name => 'general', :partial => 'users/general', :label => :label_general, :no_js_link => true },
                { :name => 'memberships', :partial => 'users/memberships', :label => :label_project_plural, :no_js_link => true },
                { :name => 'working_time', :partial => 'users/working_time', :label => :label_working_time, :user => @user, :no_js_link => true }
        ]
        if Group.givable.any? && @user.safe_attribute?(:group_ids)
          tabs.insert 1, { :name => 'groups', :partial => 'users/groups', :label => :label_group_plural, :no_js_link => true }
        end
        tabs << { :name => 'avatar', :partial => 'easy_avatars/avatar', :label => :label_avatar, :no_js_link => true, :user => @user }
        tabs << { :name => 'my_page', :partial => 'easy_page_modules_tabs', :label => :label_user_my_page, :user => @user, :page => EasyPage.find_by(page_name: 'my-page'), :no_js_link => true }
        call_hook(:helper_user_settings_tabs, :user => @user, :tabs => tabs)
        tabs
      end

      def user_profile_tabs(user)
        tabs = []
        tabs << { :name => 'basic_profile_table', :label => l(:label_general), :trigger => 'EntityTabs.showTab(this)', :partial => 'users/tabs/basic_profile_table' }
        url = users_render_tabs_path(user, :tab => 'user_activities')
        tabs << { :name => 'user_activities', :label => l(:field_activity), :trigger => "EntityTabs.showAjaxTab(this, '#{url}')" }
        url = users_render_tabs_path(user, :tab => 'user_projects')
        tabs << { :name => 'user_projects', :label => l(:label_project_plural), :trigger => "EntityTabs.showAjaxTab(this, '#{url}')" }
        if EasyAttendance.enabled?
          url = users_render_tabs_path(user, :tab => 'attendance')
          tabs << { :name => 'attendance', :label => l(:label_easy_attendance_plural), :trigger => "EntityTabs.showAjaxTab(this, '#{url}')" }
        end
        url = users_render_tabs_path(user, tab: 'user_changes_history')
        tabs << { name: 'user_changes_history', label: l(:label_user_changes_history), trigger: "EntityTabs.showAjaxTab(this, '#{url}')" }
        tabs
      end

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'UsersHelper', 'EasyPatch::UsersHelperPatch'
