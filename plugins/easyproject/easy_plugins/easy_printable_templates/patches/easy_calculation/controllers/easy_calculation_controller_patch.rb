module EasyPrintableTemplates
  module EasyCalculationControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :show, :easy_printable_templates

        def preview
          respond_to do |format|
            format.html {
              send_data(generate_preview, :type => 'text/html', :disposition => 'inline')
            }
          end
        end

        private

        def generate_preview
          @pages_size = params[:pages_size] || 'a4'
          @pages_orientation = params[:pages_orientation] || 'portrait'
          @theme = EasyPdfTheme.where(:id => params[:easy_pdf_theme].to_i).first if params[:easy_pdf_theme]
          render_to_string(template: 'easy_calculation/show', formats: [:html], layout: 'easy_calculation_printing_template')
        end

        def generate_pdf
          prepare_pdf_from_template({orientation: @pages_orientation, page_size: @pages_size, render: generate_preview})
        end

      end
    end

    module InstanceMethods
      def show_with_easy_printable_templates
        respond_to do |format|
          format.html
          format.pdf {
            filename = "#{l(:label_easy_calculation)}-#{@project.name}.pdf"
            filename = Attachment.sanitize_filename filename
            send_data(generate_pdf, :type => 'application/pdf', :disposition => 'inline', :filename => filename)
          }
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'EasyCalculationController', 'EasyPrintableTemplates::EasyCalculationControllerPatch', :if => Proc.new{ Redmine::Plugin.installed?(:easy_calculation) }
