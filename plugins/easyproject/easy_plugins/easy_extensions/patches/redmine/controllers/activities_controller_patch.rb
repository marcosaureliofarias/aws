module EasyPatch
  module ActivitiesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        helper :easy_activities

        alias_method_chain :index, :easy_extensions

        before_render :settings_before_render, only: :index

        accept_api_auth :index

        before_action :render_403, if: -> { User.current.external_client? || !User.current.allowed_to_globally?(:view_project_activity) }

        private

        def settings_before_render
          disabled_features = EasyExtensions::EasyProjectSettings.disabled_features[:modules] - ['easy_attendances']
          @activity.event_types.delete_if { |i| disabled_features.include?(i) } if @activity
        end
      end
    end

    module InstanceMethods

      def index_with_easy_extensions
        @days = Setting.activity_days_default.to_i

        if params[:range].present?
          range = params[:range].split('|')
          @date_from = Date.parse(range[0]) rescue User.current.today
          @date_to = Date.parse(range[1]) rescue @date_from + 1
        else
          # don't ask me...
          @date_to = params[:from].to_date rescue User.current.today
          @date_to   += 1
          @date_from = @date_to - @days
        end

        @with_subprojects = params[:with_subprojects].nil? ? Setting.display_subprojects_issues? : (params[:with_subprojects] == '1')
        @author           = (params[:user_id].blank? ? nil : User.active.find(params[:user_id]))

        @activity = Redmine::Activity::Fetcher.new(User.current, project: @project,
                                                   with_subprojects:      @with_subprojects,
                                                   author:                @author)

        pref = User.current.pref
        @activity.scope_select { |t| !params["show_#{t}"].nil? }

        if @activity.scope.present?
          if params[:submit].present?
            pref.activity_scope = @activity.scope
            pref.save
          end
        elsif @activity.scope.empty? && (scope = EasySetting.value('default_activity_in_overall_activity')) && scope.any?
          @activity.scope = scope
        elsif @author.nil?
          scope           = pref.activity_scope & @activity.event_types
          @activity.scope = scope.present? ? scope : :default
        else
          @activity.scope = :all
        end

        @events = @activity.easy_events(@date_from, @date_to)

        if @events.empty? || stale?(etag: [@activity.scope, @date_to, @date_from, @with_subprojects, @author, @events.first, @events.size, User.current, current_language, EasySetting.value(:show_issue_id)])
          respond_to do |format|
            format.html do
              @events_by_day = @events.group_by { |event| User.current.time_to_date(event.event_datetime) }
              render layout: false if request.xhr?
            end
            format.atom do
              title = l(:label_activity)
              if @author
                title = @author.name
              elsif @activity.scope.size == 1
                title = l("label_#{@activity.scope.first.singularize}_plural")
              end
              render_feed(@events, title: "#{@project || Setting.app_title}: #{title}")
            end
            format.api
          end
        end
      rescue ActiveRecord::RecordNotFound
        render_404
      end

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'ActivitiesController', 'EasyPatch::ActivitiesControllerPatch'
