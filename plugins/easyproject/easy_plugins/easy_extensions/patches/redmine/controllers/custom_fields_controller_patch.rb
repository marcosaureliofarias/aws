module EasyPatch
  module CustomFieldsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        helper :custom_fields
        include CustomFieldsHelper

        alias_method_chain :index, :easy_extensions
        alias_method_chain :create, :easy_extensions
        alias_method_chain :destroy, :easy_extensions
        alias_method_chain :update, :easy_extensions
        alias_method_chain :new, :easy_extensions
        alias_method_chain :find_custom_field, :easy_extensions
        alias_method_chain :build_new_custom_field, :easy_extensions

        skip_before_action :require_admin, :only => [:edit_long_text]
        before_action :find_custom_field, :only => [:edit, :update, :destroy, :toggle_disable, :edit_long_text]

        def toggle_disable
          respond_to do |format|
            format.html {
              if @custom_field.non_deletable
                @custom_field.update_attributes(:disabled => !@custom_field.disabled)
                if @custom_field.disabled
                  flash[:notice] = l(:notice_easy_custom_field_disabled)
                else
                  flash[:notice] = l(:notice_easy_custom_field_enabled)
                end
              else
                flash[:error] = l(:error_easy_custom_field_disable_deletable)
              end
              redirect_to :back
            }
          end
        end

        def update_form
          if params[:id]
            @custom_field = CustomField.find_by(:id => params[:id])
          elsif params[:type]
            @custom_field = CustomField.new_subclass_instance(params[:type])
          end
          return render_404 if @custom_field.nil?

          @custom_field.safe_attributes = params[:custom_field]

          respond_to do |format|
            format.js
          end
        end

      end
    end

    module InstanceMethods

      def index_with_easy_extensions
        respond_to do |format|
          format.html {
            @custom_fields_by_type        = CustomField.unscoped.with_group.group_by { |f| f.class.name }
            @custom_fields_projects_count = IssueCustomField.unscoped.where(is_for_all: false).joins(:projects).group(:custom_field_id).count
          }
          format.api {
            @custom_fields = CustomField.unscoped
          }
        end
      end

      def new_with_easy_extensions
        new_without_easy_extensions
        @custom_field.easy_group = EasyCustomFieldGroup.default
      end

      def require_admin
        require_admin_or_lesser_admin(:custom_fields)
      end

      def create_with_easy_extensions
        @custom_field.default_value = params[:custom_field][:default_value] if params[:custom_field] && params[:custom_field][:default_value]
        if @custom_field.save
          flash[:notice] = l(:notice_successful_create)
          call_hook(:controller_custom_fields_new_after_save, :params => params, :custom_field => @custom_field)
          redirect_back_or_default edit_custom_field_path(@custom_field)
        else
          render :action => 'new'
        end
      end

      def update_with_easy_extensions
        @custom_field.safe_attributes = params[:custom_field]
        if @custom_field.save
          call_hook(:controller_custom_fields_edit_after_save, :params => params, :custom_field => @custom_field)
          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_update)
              redirect_back_or_default edit_custom_field_path(@custom_field)
            }
            format.js { head 200 }
            format.api { render_api_ok }
          end
        else
          respond_to do |format|
            format.html { render :action => 'edit' }
            format.js { head 422 }
            format.api { render_validation_errors(@custom_field) }
          end
        end
      end

      def destroy_with_easy_extensions
        unless @custom_field.non_deletable?
          begin
            if @custom_field.destroy
              flash[:notice] = l(:notice_successful_delete)
            end
          rescue
            flash[:error] = l(:error_can_not_delete_custom_field)
          end
          redirect_back_or_default custom_fields_path(:tab => @custom_field.class.name)
        else
          flash[:error] = l(:error_can_not_delete_custom_field)
          redirect_back_or_default(:action => 'index')
        end
      end

      def edit_long_text
        @customized_entity = params[:customized_class].constantize.find(params[:customized_id])
        @custom_value      = @customized_entity.custom_field_value_for(params[:id])
        @url               = params[:url]
        if @custom_value
          return render_403 unless @custom_value.inline_editable?
          respond_to do |format|
            format.js
          end
        else
          render_404
        end
      rescue ActiveRecord::RecordNotFound, NameError, NoMethodError
        render_404
      end

      def find_custom_field_with_easy_extensions
        CustomField.unscoped do
          find_custom_field_without_easy_extensions
        end
      end

      # redmine 4
      def build_new_custom_field_with_easy_extensions
        @custom_field = CustomField.new_subclass_instance(params[:type])
        if @custom_field.nil?
          render :action => 'select_type'
        else
          @custom_field.safe_attributes = params[:custom_field]
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'CustomFieldsController', 'EasyPatch::CustomFieldsControllerPatch'
