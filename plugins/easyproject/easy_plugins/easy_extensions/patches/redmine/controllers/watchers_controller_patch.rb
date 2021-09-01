module EasyPatch
  module WatchersControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        before_action :get_available_watchers, :only => [:new, :autocomplete_for_user]
        before_action :find_groups, :only => [:create]
        skip_before_action :find_project, :only => [:toggle_members]
        skip_before_action :authorize, :only => [:destroy], :if => lambda { (params[:user_id].to_i == User.current.id) && User.current.allowed_to?(:"add_#{params[:object_type].to_s.underscore}_watchers", @project) }

        alias_method_chain :autocomplete_for_user, :easy_extensions
        alias_method_chain :new, :easy_extensions
        alias_method_chain :create, :easy_extensions
        alias_method_chain :destroy, :easy_extensions
        alias_method_chain :users_for_new_watcher, :easy_extensions
        alias_method_chain :find_project, :easy_extensions

        private

        def get_available_watchers
          @available_watchers = if @watched
                                  @watched.addable_watcher_users
                                else
                                  User.member_of(@project)
                                end
          @user_count         = @available_watchers.count
          @user_pages         = Redmine::Pagination::Paginator.new @user_count, per_page_option, params['page']
          @available_watchers = @available_watchers.to_a.slice(@user_pages.offset, @user_pages.per_page) || []

          scope        = @watched.available_groups
          @group_count = scope.count
          @group_pages = Redmine::Pagination::Paginator.new @group_count, per_page_option, params['group_page'], :group_page

          if params[:easy_query_q]
            if params[:easy_query_q].present?
              @available_watcher_groups = scope.like(params[:easy_query_q]).sorted
            else
              @available_watcher_groups = scope.limit(Watcher::GROUP_LIMIT).sorted
            end
          else
            @available_watcher_groups = scope.offset(@group_pages.offset).limit(@group_pages.per_page).sorted
          end
        end

        def find_groups
          @groups = Group.where(:id => params[:watcher][:group_ids]) if params[:watcher]
          @groups ||= []
        end
      end
    end

    module InstanceMethods

      def autocomplete_for_user_with_easy_extensions
        unless params[:reset]
          if @watched && params[:easy_query_q]
            @users = @watched.project.users.non_system_flag.sorted.like(params[:easy_query_q]).limit(Watcher::USER_LIMIT)
            @users -= @watched.watcher_users
          end
        end
        if params[:page] || params['group_page']
          render(:partial => 'watchers/new_page', locals: { watched: @watched, :watchables => @watchables, available_watchers: @users || @available_watchers })
        else
          render(:partial => 'watchers/new', locals: { watched: @watched, :watchables => @watchables, available_watchers: @users || @available_watchers, groups: @available_watcher_groups })
        end
      end

      def new_with_easy_extensions
        @users = users_for_new_watcher
        respond_to do |format|
          format.js
        end
      end

      def create_with_easy_extensions
        if @groups.any?
          project_member_group_ids = @project.memberships.where(:user_id => @groups).pluck(:user_id)
          @groups.each do |group|
            if project_member_group_ids.include?(group.id)
              @watchables.each do |watchable|
                Watcher.create(watchable: watchable, group: group)
              end
            end
          end
        end

        create_without_easy_extensions
      end

      def destroy_with_easy_extensions
        user = Principal.find(params[:user_id])
        @watchables.each do |watchable|
          watchable.set_watcher(user, false)
        end
        respond_to do |format|
          format.html { redirect_to :back }
          format.js
          format.api { render_api_ok }
        end
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def users_for_new_watcher_with_easy_extensions
        scope = nil
        if (params[:easy_query_q].blank? || params[:q].blank?) && @project.present?
          scope = @project.users.non_system_flag
        else
          scope = User.non_system_flag.limit(Watcher::USER_LIMIT)
        end
        users = scope.active.visible.sorted.like(params[:easy_query_q] || params[:q]).to_a
        if @watchables && @watchables.size == 1
          users -= @watchables.first.watcher_users
        end
        users
      end

      def find_project_with_easy_extensions
        find_project_without_easy_extensions
        @watched = @watchables.first if @watchables.present?
      end
    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'WatchersController', 'EasyPatch::WatchersControllerPatch'
