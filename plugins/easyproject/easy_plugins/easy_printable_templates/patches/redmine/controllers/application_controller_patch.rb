module EasyPrintableTemplates
  module ApplicationControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        helper :easy_printable_templates
        include EasyPrintableTemplatesHelper
        helper :easy_printable_template_pages
        include EasyPrintableTemplatePagesHelper

        def prepare_pdf_from_template(options = {})
          @render_pdf = true
          render = options.delete(:render)

          pages_orientation = options[:orientation] || params[:pages_orientation] || (@easy_printable_template && @easy_printable_template.pages_orientation) || 'portrait'
          pages_size = options[:page_size] || params[:pages_size] || (@easy_printable_template && @easy_printable_template.pages_size) || 'a4'

          if pages_size == 'custom'
            pages_height = "#{(params[:pages_height].presence || 1_000).to_i}"
            pages_width = "#{(params[:pages_width].presence || 1_000).to_i}"

            # Older version of wkhtmltopdf does not support "custom" value
            pages_size = nil
            options[:page_size] = nil

            # Or switch height with width
            pages_orientation = 'portrait'
          end

          unless render
            render_options = {
              template: 'easy_printable_templates/preview_for_pdf',
              layout: 'layouts/easy_printable_template_preview',
              formats: [:html],
              locals: { pages_orientation: pages_orientation,
                        pages_size: pages_size,
                        pages_height: pages_height,
                        pages_width: pages_width }
            }
            options.reverse_merge!( page_size: pages_size,
                                    orientation: pages_orientation,
                                    page_width: pages_width,
                                    page_height: pages_height )
            render = render_to_string(render_options)
          end

          kit = EasyPrintableTemplates::PDFEasyKit.new(render, options)
          tmps = []
          begin
            used_stylesheets.dup.each do |source|
              asset_path = [Rails.public_path]
              asset_path << "#{source.gsub(/\.css$/, '')}.css"
              if File.exist?(File.join(asset_path))
                kit.stylesheets << File.absolute_path(File.join(asset_path))
              elsif Rails.application.assets && (asset = Rails.application.assets.find_asset(File.basename(source)))
                # devel mode
                Rails.logger.warn("prepare_pdf_from_template asset: #{source} not found, try to use pipeline fallback")
                file = asset.logical_path
                t = Tempfile.new([file, '.css'])
                t.write(asset.source); t.rewind
                tmps << t
                kit.stylesheets << t.path
              end
            end

            pdf = kit.to_pdf
          ensure
            tmps.each do |t|
              t.close; t.unlink
            end
          end

          pdf
        end

        def create_pdf_attachment(entity, options = {})
          filename = options[:hook_options] && options[:hook_options][:filename].present? ? options[:hook_options][:filename] : "#{format_date(Date.today)} - #{@easy_printable_template.name}.pdf"
          hook_options = {entity: entity, filename: filename, options: {filename: filename, pdfkit_options: {}}}
          hook_options = hook_options.merge!(options[:hook_options]) if options[:hook_options]

          call_hook(:controller_easy_printable_templates_create_pdf_attachment, hook_options)

          filename = entity.pdf_attachment_filename if entity.respond_to? :pdf_attachment_filename

          if (pdf_string = prepare_pdf_from_template(hook_options[:options][:pdfkit_options]))
            filename = Attachment.sanitize_filename(filename)
            generated_file = ActionDispatch::Http::UploadedFile.new({filename: filename, type: Redmine::MimeType.of('x.pdf'), tempfile: StringIO.new(pdf_string)})

            entity.clear_current_journal if entity.respond_to?(:clear_current_journal)
            journal = entity.init_journal(User.current) if entity.respond_to?(:init_journal)

            saved_attachments = Attachment.attach_files(entity, ['file' => generated_file, 'description' => filename])
            current_pdf = (saved_attachments[:files].first || saved_attachments[:new_versions].first)

            call_hook(:model_update_current_pdf, :entity => entity, :current_pdf => current_pdf) if current_pdf

            journal.save if journal
            true
          else
            nil
          end
        end
      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'ApplicationController', 'EasyPrintableTemplates::ApplicationControllerPatch'
