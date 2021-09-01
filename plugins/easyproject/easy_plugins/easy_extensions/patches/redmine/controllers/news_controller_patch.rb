module EasyPatch
  module NewsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        before_action :mark_as_read, :only => [:show]
        after_action :mark_as_read, :only => [:create]
        after_action :notify_recipients_after_news_added, :only => [:create]

        # cache_sweeper :my_page_others_news_sweeper

        alias_method_chain :index, :easy_extensions

        private

        def mark_as_read
          @news.mark_as_read if @news && !@news.new_record?
          #expire_fragment("my_page_others_news_user_#{User.current.id}")
        end

        def notify_recipients_after_news_added
          if !@news.new_record? && Setting.notified_events.include?('news_added') && @news.recipients.any? && !@news.project&.is_planned
            flash[:notice] << "<br>#{l(:label_issue_notice_recipients)}"
            flash[:notice] << @news.recipients.join(', ')
            flash[:notice] = flash[:notice].html_safe
          end
        end

      end
    end

    module InstanceMethods

      def index_with_easy_extensions
        case params[:format]
        when 'xml', 'json'
          @offset, @limit = api_offset_and_limit
        else
          @limit = 10
        end

        scope = @project ? @project.news.visible : News.visible

        @news_count = scope.count
        @news_pages = Redmine::Pagination::Paginator.new @news_count, @limit, params['page']

        if request.xhr? && @news_pages.last_page.to_i < params['page'].to_i
          render_404
          return false
        end

        @offset ||= @news_pages.offset
        @newss  = scope.preload([:author, :project]).
            order(spinned: :desc, created_on: :desc).
            limit(@limit).
            offset(@offset).
            to_a

        respond_to do |format|
          format.html {
            @news = News.new # for adding news inline
            render :layout => false if request.xhr?
          }
          format.api
          format.atom { render_feed(@newss, :title => (@project ? @project.name : Setting.app_title) + ": #{l(:label_news_plural)}") }
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'NewsController', 'EasyPatch::NewsControllerPatch'
