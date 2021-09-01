module EasyPatch
  module IssueStatusesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        alias_method_chain :require_admin, :easy_extensions
        alias_method_chain :require_admin_or_api_request, :easy_extensions
        alias_method_chain :update, :easy_extensions
        alias_method_chain :destroy, :easy_extensions

        def edit_reassignment
          @issue_status   = IssueStatus.find_by(id: params[:id])
          @issue_statuses = IssueStatus.where.not(id: params[:id])
        end

        def update_reassignment
          @issue_status    = IssueStatus.find_by(id: params[:id])
          @issue_status_to = IssueStatus.find_by(id: params[:issue_status_to_id]) unless params[:issue_status_to_id].blank?

          if @issue_status_to && @issue_status && @issue_status != @issue_status_to
            @issue_status.replace_with(@issue_status_to.id)
            destroy_issue_status(@issue_status)
          else
            flash[:error] = l(:error_unable_delete_issue_status)
            render action: :edit
          end
        end

        def destroy_issue_status issue_status
          if Issue.where(status_id: issue_status.id).any? || Tracker.where(default_status_id: issue_status.id).any?
            flash[:error] = l(:error_unable_delete_issue_status)
            if IssueStatus.count < 2
              redirect_to issue_statuses_path
            else
              redirect_to issue_status_edit_reassignment_path(@issue_status)
            end
          else
            issue_status.destroy
            redirect_to issue_statuses_path
          end
        end

        private :destroy_issue_status

      end
    end

    module InstanceMethods

      def update_with_easy_extensions
        @issue_status                 = IssueStatus.find(params[:id])
        @issue_status.safe_attributes = params[:issue_status]
        if @issue_status.save
          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_update)
              redirect_to issue_statuses_path(:page => params[:page])
            }
            format.js { head :ok }
            format.api { render_api_ok }
          end
        else
          respond_to do |format|
            format.html { render :action => 'edit' }
            format.js { head 422 }
            format.api { render_validation_errors(@issue_status) }
          end
        end
      end

      def destroy_with_easy_extensions
        @issue_status = IssueStatus.find(params[:id])
        destroy_issue_status(@issue_status)
      end

      def require_admin_with_easy_extensions
        require_admin_or_lesser_admin(:issue_statuses)
      end

      def require_admin_or_api_request_with_easy_extensions
        require_admin_or_api_request_or_lesser_admin(:issue_statuses)
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'IssueStatusesController', 'EasyPatch::IssueStatusesControllerPatch'
