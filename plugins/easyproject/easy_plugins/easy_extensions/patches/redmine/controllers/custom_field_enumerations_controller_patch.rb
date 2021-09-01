module EasyPatch
  module CustomFieldEnumerationsControllerPatch
    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :create, :easy_extensions

      end

    end

    module InstanceMethods

      def create_with_easy_extensions
        @value            = @custom_field.enumerations.build
        @value.attributes = enumeration_params
        if @value.save
          respond_to do |format|
            format.html { redirect_to custom_field_enumerations_path(@custom_field) }
            format.js
          end
        else
          respond_to do |format|
            format.html { redirect_to custom_field_enumerations_path(@custom_field), alert: @value.errors.full_messages.join('<br>').html_safe }
            format.js { render :plain => "window.showFlashMessage('error', '#{@value.errors.full_messages.join('<br>').html_safe}', 1000);" }
          end
        end
      end

      def require_admin
        require_admin_or_lesser_admin(:custom_fields)
      end
    end

  end
end

EasyExtensions::PatchManager.register_controller_patch 'CustomFieldEnumerationsController', 'EasyPatch::CustomFieldEnumerationsControllerPatch'

