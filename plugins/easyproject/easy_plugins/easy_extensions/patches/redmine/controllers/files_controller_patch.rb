module EasyPatch
  module FilesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :create, :easy_extensions
      end
    end

    module InstanceMethods

      def create_with_easy_extensions
        version_id = params[:version_id] || (params[:file] && params[:file][:version_id])
        container  = version_id.blank? ? @project : @project.versions.find_by(id: version_id)
        return render_404 unless container

        #attachments = Attachment.attach_files(container, (params[:attachments] || (params[:file] && params[:file][:token] && params)))
        attachments = container.save_attachments_without_easy_extensions(params[:attachments] || (params[:file] && params[:file][:token] && params), User.current)
        container.attach_saved_attachments

        render_attachment_warning_if_needed(container)

        if attachments[:files].present?
          if Setting.notified_events.include?('file_added')
            Mailer.deliver_attachments_added(attachments[:files])
          end
          respond_to do |format|
            format.html {
              flash[:notice] = l(:label_file_added)
              redirect_to project_files_path(@project) }
            format.api { render_api_ok }
          end
        else
          respond_to do |format|
            format.html {
              flash.now[:error] = l(:label_attachment) + " " + l('activerecord.errors.messages.invalid')
              new
              render :action => 'new' }
            format.api { render :status => :bad_request }
          end
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'FilesController', 'EasyPatch::FilesControllerPatch'
