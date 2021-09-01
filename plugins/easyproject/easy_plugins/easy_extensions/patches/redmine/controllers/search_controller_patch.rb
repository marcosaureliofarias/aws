module EasyPatch
  module SearchControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        helper :custom_fields

        alias_method_chain :index, :easy_extensions

        def object_type_allowed_to_condition(object_type, project)
          User.current.allowed_to?("view_#{object_type}".to_sym, project)
        end

      end
    end

    module InstanceMethods

      def index_with_easy_extensions
        @question = params[:q] || ''
        @question.strip!
        @all_words          = params[:all_words] ? params[:all_words].present? : true
        @titles_only        = params[:titles_only] ? params[:titles_only].present? : false
        @search_attachments = params[:attachments].presence || '0'
        @open_issues        = params[:open_issues].present? ? params[:open_issues].to_boolean : true

        case params[:format]
        when 'xml', 'json'
          @offset, @limit = api_offset_and_limit
        else
          @offset = nil
          @limit  = Setting.search_results_per_page.to_i
          @limit  = 10 if @limit == 0
        end

        # Quick jump to an issue
        if (m = @question.match(/^#?(\d+)$/)) && (issue = Issue.visible.find_by(id: m[1].to_i))
          redirect_to issue_path(issue)
          return
        end

        @scope_select =
            if params[:scope_type].present?
              params[:scope_type]
            elsif @project && @project.descendants.exists?
              'subprojects'
            elsif @project
              'project'
            else
              'all'
            end

        projects_to_search =
            case @scope_select
            when 'all'
              nil
            when 'my_projects'
              User.current.projects
            when 'subprojects'
              @project && @project.self_and_descendants.to_a
            else
              # Search in selected projects
              projects = Project.where(id: params[:scope])
              if projects.count > 1
                projects.to_a
              elsif projects.count == 1
                projects.first
              else
                @project
              end
            end

        @object_types = Redmine::Search.available_search_types.dup
        if projects_to_search.is_a?(Project)
          # don't search projects
          @object_types.delete('projects')
          # only show what the user is allowed to view
          @object_types = @object_types.select { |o| self.object_type_allowed_to_condition(o, projects_to_search) }
        end

        @scope = @object_types.select { |t| params[t] }

        if @scope.empty?
          default_entity_types = Array(EasySetting.value('easy_search_default_object_types')).reject(&:blank?) & @object_types
          if default_entity_types.present?
            @scope = default_entity_types
          else
            @scope = Array(@object_types.first) # By default search only in first type (task)
          end
        end

        fetcher = Redmine::Search::Fetcher.new(
            @question, User.current, @scope, projects_to_search,
            all_words:   @all_words,
            titles_only: @titles_only,
            attachments: @search_attachments,
            open_issues: @open_issues,
            cache:       params[:page].present?,
            params:      params.to_unsafe_hash
        )

        if fetcher.tokens.present?
          @result_count         = fetcher.result_count
          @result_count_by_type = fetcher.result_count_by_type
          @tokens               = fetcher.tokens

          @result_pages = Redmine::Pagination::Paginator.new @result_count, @limit, params['page']
          @offset       ||= @result_pages.offset
          @results      = fetcher.results(@offset, @result_pages.per_page)
        else
          @question = ''
        end

        respond_to do |format|
          format.html { render layout: false if request.xhr? }
          format.api { @results ||= []; render layout: false }
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'SearchController', 'EasyPatch::SearchControllerPatch'
