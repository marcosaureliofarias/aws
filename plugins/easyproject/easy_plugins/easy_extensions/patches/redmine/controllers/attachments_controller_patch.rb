module EasyPatch
  module AttachmentsControllerPatch

    def self.included(base)

      base.class_eval do
        base.include(InstanceMethods)

        helper CustomFieldsHelper

        before_action :find_attachment, :only => [:show, :download, :thumbnail, :destroy, :bulk_destroy, :bulk_download_as_zip, :attachment_custom_fields, :revert_to_version]
        before_action :file_readable, :read_authorize, :only => [:show, :download, :thumbnail]
        before_action :delete_authorize, :only => :destroy
        before_action :authorize_global, :only => :upload
        before_action :mark_as_read, :only => [:show, :download]

        #        cache_sweeper :my_page_others_documents_sweeper

        alias_method_chain :destroy, :easy_extensions
        alias_method_chain :find_attachment, :easy_extensions
        alias_method_chain :upload, :easy_extensions
        alias_method_chain :show, :easy_extensions
        alias_method_chain :download, :easy_extensions
        alias_method_chain :thumbnail, :easy_extensions

        accept_api_auth_actions << :attach

        def ensure_easy_attendance
        end

        # Destroy version of attachment
        def destroy_version
          av          = AttachmentVersion.find(params[:id])
          @attachment = av.attachment
          return unless delete_authorize
          if @attachment.container
            if @attachment.container.respond_to?(:init_journal)
              @attachment.container.init_journal(User.current)
            end
            if @attachment.versions.count <= 1
              @attachment.container.attachments.delete(@attachment)
            elsif @attachment.container.respond_to?(:current_journal)
              @attachment.container.current_journal.details << JournalDetail.new(
                  :property  => 'attachment_version',
                  :prop_key  => av.id,
                  :old_value => av.filename
              )
              @attachment.container.current_journal.save
            end
          end
          # Make sure association callbacks are called
          av.destroy
          flash[:notice] = l(:notice_successful_delete)
          redirect_back_or_default(home_path)
        rescue ActiveRecord::RecordNotFound
          render_404
        end

        # Revert attachment version to select version
        def revert_to_version
          return unless update_authorize
          version = @attachment.versions.find_by(version: params[:version_num])
          if version && @attachment.revert_to!(version)
            flash[:notice] = l('attachments.revert_to.successfully', :version => params[:version_num])
          else
            flash[:error] = l('attachments.revert_to.failed', :version => params[:version_num], :current_v => @attachment.version)
          end
          redirect_back_or_default(home_path)
        end

        def new
          @container = params[:entity_type].classify.constantize.find(params[:entity_id])
          respond_to do |format|
            format.js
          end
        end

        def new_version
          @attachment = Attachment.find(params[:id])
          return unless update_authorize
          @container                                = @attachment.container
          params[:custom_version_for_attachment_id] = @attachment.id

          respond_to do |format|
            format.js { render(:action => 'new') }
          end
        end

        def attach
          attachments_params = params.to_unsafe_hash
          if attachments_params['attach'].present?
            attachments_params = attachments_params['attach']
          end

          entity_type = attachments_params.delete('entity_type')
          entity_id   = attachments_params.delete('entity_id')
          @container  = entity_type.classify.constantize.find(entity_id)
          return deny_access if @container.respond_to?(:attachments_editable?) && !@container.attachments_editable?
          @container.init_journal(User.current) if @container.respond_to?(:init_journal)
          @attached = Attachment.attach_files(@container, attachments_params['attachments'])
          @container.current_journal.save if @container.respond_to?(:current_journal) && @container.current_journal
          files = @attached[:files] + @attached[:new_versions]
          if @container.is_a?(Document) && files.present? && Setting.notified_events.include?('document_added') && !@container.project.is_planned
            Mailer.deliver_attachments_added(files)
          end
          render_attachment_warning_if_needed(@container) unless request.xhr?

          respond_to do |format|
            format.html {
              redirect_back_or_default(begin
                                         polymorphic_path(@container);
                                       rescue;
                                         home_path
                                       end)
            }
            format.js
            format.api
          end
        rescue ActiveRecord::RecordNotFound, NameError
          render_404
        end

        def webdav_modal
          return false if find_attachment == false

          respond_to do |format|
            format.js
          end
        end

        def bulk_destroy
          if @attachments.any? {|a| !a.deletable? }
            deny_access
            return
          end
          @attachments.group_by(&:container).each do |container, attachments|
            delete_attachments(container, attachments)
          end

          flash[:notice] = l(:notice_successful_delete)

          respond_to do |format|
            format.html { redirect_to_referer_or(@project.nil? ? home_path : project_documents_path(@project)) }
            format.js
            format.api { render_api_ok }
          end
        end

        private

        def mark_as_read
          @attachment.mark_as_read(User.current) if @attachment
        end

        def message
          return if @attachment.nil?
          if @attachment.is_message?
            @email = Mail.new(File.binread(@attachment.diskfile))
          elsif @attachment.content_type == 'application/vnd.ms-outlook' && (eml = EasyExtensions::EasyMsgReader.new(@attachment.diskfile).to_eml)
            @email = Mail.new(eml)
          end
        end

        def message_short_cid(cid)
          i = cid.index('_')
          cid[0, i] if i
        end

        def delete_attachments(container, attachments = container.attachments)
          if container.respond_to?(:init_journal)
            container.init_journal(User.current)
          end
          if container
            # Make sure association callbacks are called
            container.attachments.delete(attachments)
          else
            @scope.destroy(attachments.map(&:id))
          end
          true
        end
      end

    end

    module InstanceMethods

      def destroy_with_easy_extensions
        success = delete_attachments(@attachment.container, Array.wrap(@attachment))

        flash[:notice] = l(:notice_successful_delete) if success

        respond_to do |format|
          format.html { redirect_to_referer_or(@project.nil? ? home_path : project_path(@project)) }
          format.js
          format.api { render_api_ok }
        end
      end

      def thumbnail_with_easy_extensions
        if @attachment.thumbnailable? && tbnail = @attachment.thumbnail(:size => params[:size])
          if stale?(:etag => tbnail, :template => false)
            # fix for the Anti-MIME-Sniffing header X-Content-Type-Options = 'nosniff'
            content_type = if File.extname(tbnail) == '.thumb'
                             Redmine::MimeType.of('x.jpg').to_s # we always generate JPGs as thumbnails, see generate_with_easy_extensions
                           else
                             # if the original file is used as thumbnail
                             detect_content_type(@attachment)
                           end

            send_file tbnail,
                      :filename    => filename_for_content_disposition(@attachment.filename),
                      :type        => content_type,
                      :disposition => 'inline'
          end
        else
          # No thumbnail for the attachment or thumbnail could not be created
          head 404
        end
      end

      def upload_with_easy_extensions
        # Make sure that API users get used to set this content type
        # as it won't trigger Rails' automatic parsing of the request body for parameters
        unless request.content_type == 'application/octet-stream'
          render_406
          return
        end
        @attachment                           = Attachment.new(:file => request.body)
        @attachment.author                    = User.current
        @attachment.filename                  = params[:filename].presence || Redmine::Utils.random_hex(16)
        @attachment.skip_description_required = true

        saved = @attachment.save

        @attachment_for_custom_fields = Attachment.where(:id => params[:custom_version_for_attachment_id]).first_or_initialize

        respond_to do |format|
          format.js
          format.api {
            if saved
              render :action => 'upload', :status => :created
            else
              render_validation_errors(@attachment)
            end
          }
        end
      end

      def show_with_easy_extensions
        file_size_displayed = @attachment.filesize <= Setting.file_max_size_displayed.to_i.kilobyte
        if file_size_displayed && message
          respond_to do |format|
            format.html do
              part = (Setting.text_formatting == 'HTML') ? (@email.html_part || @email.text_part) : (@email.text_part || @email.html_part)
              part ||= @email if @email.text?
              if part
                encoding = Mail::RubyVer.respond_to?(:pick_encoding) ? Mail::RubyVer.pick_encoding(part.charset).to_s : part.charset
                body     = part.body.decoded
                @content = begin
                  convert_to_utf8(body, encoding)
                rescue *Redmine::CodesetUtil::ENCODING_EXCEPTIONS
                  Redmine::CodesetUtil.replace_invalid_utf8(body)
                end
                @content = simple_format_without_paragraph(@content) if part.mime_type != 'text/html'
              end

              @content     ||= ''
              @subject     = @email.subject
              @attachments = @email.attachments

              if params[:content_filename] || params[:cid]
                fn         = params[:content_filename].to_s
                cid        = params[:cid].to_s
                short_cid  = message_short_cid(cid)
                attachment = @attachments.detect do |a|
                  a.cid == cid ||
                      (!short_cid.nil? && (message_short_cid(a.cid) == short_cid) && a.filename == fn) ||
                      a.filename == fn
                end
                attachment ||= @attachments.detect { |a| a.filename == fn }
              end

              if attachment
                tmp = Tempfile.new(File.basename(attachment.cid.to_s))
                begin
                  tmp.binmode
                  tmp.write(attachment.body.decoded.to_s)
                  disposition = attachment.inline? ? 'inline' : 'attachment'
                  send_file tmp.path,
                            :filename    => filename_for_content_disposition(attachment.filename),
                            :type        => attachment.content_type,
                            :disposition => disposition
                ensure
                  tmp.close if tmp
                end
              else
                render :action => 'message'
              end
            end
            format.api
          end
        else
          if @attachment.is_diff? || (@attachment.is_text? && file_size_displayed) || @attachment.is_image? || api_request? || params[:no_download]
            show_without_easy_extensions
          else
            download
          end
        end
      end

      def download_with_easy_extensions
        @attachment.increment_download
        if stale?(:etag => @attachment.digest, :template => false)
          # images are sent inline
          send_file @attachment.diskfile, :filename => filename_for_content_disposition(@attachment.filename),
                    :type                           => detect_content_type(@attachment),
                    :disposition                    =>  "#{disposition(@attachment)}; filename*= UTF-8''#{filename_for_content_disposition(@attachment.filename)}"
        end
      end

      def bulk_download_as_zip
        if @attachments.blank?
          flash[:error] = l('attachments.attachments_missing')
          redirect_back_or_default(home_path)
        else
          prefix         = @attachments.first.container_type.present? ? @attachments.first.container_type.underscore.pluralize : 'attachments'
          zip_filename   = prefix + '_' + Time.now.strftime("%Y-%m-%d") + '.zip'
          @missing_files = []
          Zip.unicode_names = true

          archived_file_names = []
          zip_data = nil
          begin
            buffer = Zip::OutputStream.write_buffer do |zos|
              @attachments.each do |attachment|
                filename = attachment.filename
                # rename the file if a file with the same name already exists
                dup_count = 0
                while archived_file_names.include?(filename)
                  dup_count += 1
                  extname = File.extname(attachment.filename)
                  basename = File.basename(attachment.filename, extname)
                  filename = "#{basename}(#{dup_count})#{extname}"
                end
                zos.put_next_entry(filename)
                zos << IO.binread(attachment.diskfile)
                archived_file_names << filename
              end
            end
            zip_data = buffer.string
          ensure
            buffer&.close
          end

          if archived_file_names.any?
            send_data(zip_data, type: Redmine::MimeType.of(zip_filename), filename: zip_filename)
          else
            flash[:error] = l('attachments.attachments_missing')
            redirect_back_or_default(home_path)
          end
        end
      end

      def attachment_custom_fields
        render :layout => !request.xhr?
      end

      private

      def find_attachment_with_easy_extensions
        @scope        = params[:version] ? AttachmentVersion : Attachment
        @attachments = @scope.preload(:container).find(params[:ids]) if params[:ids]
        @attachment  = @attachments ? @attachments.first : @scope.find(params[:id])
        # Show 404 if the filename in the url is wrong
        raise ActiveRecord::RecordNotFound if @attachment && (params[:filename] && params[:filename] != @attachment.filename)
        @project = @attachment.project
      rescue ActiveRecord::RecordNotFound, NameError
        render_404
      end

      def convert_to_utf8(str, encoding)
        if !str.nil? && encoding.to_s.casecmp('utf-7').zero? && Net::IMAP.respond_to?(:decode_utf7)
          str.force_encoding('UTF-8')
          Redmine::CodesetUtil.to_utf8(Net::IMAP.decode_utf7(str), 'UTF-8')
        else
          Redmine::CodesetUtil.to_utf8(str, encoding)
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'AttachmentsController', 'EasyPatch::AttachmentsControllerPatch'
