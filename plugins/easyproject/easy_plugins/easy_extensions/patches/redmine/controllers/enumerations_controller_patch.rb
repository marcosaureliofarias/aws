module EasyPatch
  module EnumerationsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :create, :easy_extensions
        alias_method_chain :update, :easy_extensions
        alias_method_chain :enumeration_params, :easy_extensions

      end
    end

    module InstanceMethods

      def create_with_easy_extensions
        @enumeration.attributes = enumeration_params
        if @enumeration.save
          call_hook(:controller_enumerations_create_after_save, { :enumeration => @enumeration })
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default enumerations_path
        else
          render :action => 'new'
        end
      end

      def update_with_easy_extensions
        @enumeration.attributes = enumeration_params
        if @enumeration.save
          call_hook(:controller_enumerations_edit_after_save, { :enumeration => @enumeration })

          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_update)
              redirect_back_or_default enumerations_path
            }
            format.js { head 200 }
            format.api { render_api_ok }
          end
        else
          respond_to do |format|
            format.html { render :action => 'edit' }
            format.js { head 422 }
            format.api { render_validation_errors(@enumeration) }
          end
        end
      end

      def enumeration_params_with_easy_extensions
        params[:enumeration].permit! if params[:enumeration]
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'EnumerationsController', 'EasyPatch::EnumerationsControllerPatch'
