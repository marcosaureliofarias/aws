module EasyPatch
  module TrackersControllerPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        alias_method_chain :destroy, :easy_extensions
        alias_method_chain :require_admin, :easy_extensions
        alias_method_chain :require_admin_or_api_request, :easy_extensions
        alias_method_chain :update, :easy_extensions
        alias_method_chain :edit, :easy_extensions
        alias_method_chain :new, :easy_extensions

        def move_issues
          @tracker  = Tracker.find(params[:id])
          @trackers = Tracker.where("#{Tracker.table_name}.id <> ?", @tracker.id)
          if request.post?
            unless params[:tracker_to_id].blank? || params[:tracker_to_id] == @tracker.id.to_s
              @tracker_to = Tracker.find(params[:tracker_to_id])
              cf_map      = params[:custom_field_map] ? params[:custom_field_map].permit!.to_h : {}
              @tracker.move_issues(@tracker_to, Hash[cf_map.map { |k, v| [k.to_i, v.blank? ? nil : v.to_i] }])
              @tracker.reload
              unless @tracker.issues.empty?
                flash[:error] = l(:error_can_not_delete_tracker)
                redirect_to tracker_move_issues_path(@tracker)
              else
                @tracker.destroy
                redirect_to :action => 'index'
              end
            end
          end
        end

        def custom_field_mapping
          begin
            @tracker    = Tracker.includes(:custom_fields).find(params[:id])
            @tracker_to = Tracker.includes(:custom_fields).find(params[:tracker_to_id])
          rescue ActiveRecord::RecordNotFound
            render_404
            return
          end
          @custom_field_data = @tracker.custom_field_mapping_data(@tracker_to)
          render :action => 'custom_field_mapping', :layout => false if request.xhr?
        end

      end
    end

    module InstanceMethods

      def destroy_with_easy_extensions
        @tracker = Tracker.find(params[:id])
        unless @tracker.issues.empty?
          flash[:error] = l(:error_can_not_delete_tracker)
          if Tracker.count < 2
            redirect_to :action => 'index'
          else
            redirect_to tracker_move_issues_path(@tracker)
          end
        else
          @tracker.destroy
          redirect_to trackers_path
        end
      end

      def edit_with_easy_extensions
        edit_without_easy_extensions
        @trackers = Tracker.where.not(id: @tracker.id).sorted.to_a
        @projects = Project.active_and_planned
      end

      def new_with_easy_extensions
        new_without_easy_extensions
        @projects = Project.active_and_planned
      end

      def update_with_easy_extensions
        @tracker                 = Tracker.find(params[:id])
        @tracker.safe_attributes = params[:tracker]
        if @tracker.save
          # workflow override
          if params[:override_workflow_by].present? && (copy_from = Tracker.find_by(id: params[:override_workflow_by]))
            @tracker.workflow_rules.destroy_all if @tracker.workflow_rules.any?
            @tracker.copy_workflow_rules(copy_from)
          end
          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_update)
              redirect_to trackers_path(:page => params[:page])
            }
            format.js { head 200 }
            format.api { render_api_ok }
          end
        else
          respond_to do |format|
            format.html {
              edit
              render :action => 'edit'
            }
            format.js { head 422 }
            format.api { render_validation_errors(@tracker) }
          end
        end
      end

      def require_admin_with_easy_extensions
        require_admin_or_lesser_admin(:trackers)
      end

      def require_admin_or_api_request_with_easy_extensions
        require_admin_or_api_request_or_lesser_admin(:trackers)
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'TrackersController', 'EasyPatch::TrackersControllerPatch'
