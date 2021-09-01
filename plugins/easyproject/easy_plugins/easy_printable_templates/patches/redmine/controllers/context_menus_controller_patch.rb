module EasyPrintableTemplates
  module ContextMenusControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def easy_printable_templates
          @easy_printable_templates = EasyPrintableTemplate.where(:id => params[:ids]).all
          (render_404; return) unless @easy_printable_templates.present?

          if (@easy_printable_templates.size == 1)
            @easy_printable_template = @easy_printable_templates.first
          end

          @back_url = back_url

          render :layout => false
        end

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'ContextMenusController', 'EasyPrintableTemplates::ContextMenusControllerPatch'
