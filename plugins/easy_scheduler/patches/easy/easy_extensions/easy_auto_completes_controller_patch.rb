module EasyScheduler
  module EasyAutoCompletesControllerPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def easy_scheduler_issues
          @entities = get_easy_scheduler_issues(params[:term], EasySetting.value('easy_select_limit').to_i)

          @name_column = :to_s
          respond_to do |format|
            format.api { render template: 'easy_auto_completes/entities_with_id', formats: [:api] }
          end
        end

        def get_easy_scheduler_issues(term='', limit=nil)
          get_easy_scheduler_issues_scope(term, limit).to_a
        end

        def get_easy_scheduler_issues_scope(term = '', limit = nil, options = {})
          options[:start_date] ||= Date.safe_parse(params[:start_date]) if params[:start_date]
          options[:due_date]   ||= Date.safe_parse(params[:due_date])   if params[:due_date]
          # should take primary user for new allocation
          # should take assignee for edit
          scope = Issue.assigned_to(params[:user_id].presence || User.current.id)
          if term =~ /^\d+$/
            scope = scope.where(id: term)
          else
            scope = scope.like(term)
          end
          scope = scope.where(start_date: nil).or(Issue.where("#{Issue.table_name}.start_date <= ?", options[:start_date])) if options[:start_date]
          scope = scope.where(due_date: nil).or(Issue.where("#{Issue.table_name}.due_date >= ?", options[:due_date])) if options[:due_date]
          scope.limit(limit)
        end

      end
    end

    module InstanceMethods      
    end

    module ClassMethods

    end
  end
end

RedmineExtensions::PatchManager.register_controller_patch 'EasyAutoCompletesController', 'EasyScheduler::EasyAutoCompletesControllerPatch'
