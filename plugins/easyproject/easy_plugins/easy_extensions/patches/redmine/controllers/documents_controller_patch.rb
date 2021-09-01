module EasyPatch
  module DocumentsControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        before_action :csv, :only => [:index]
        before_action :mark_as_read, only: [:show]
        after_action :mark_as_read, only: [:create]
      
        accept_api_auth :index, :show, :create, :update, :destroy

        menu_item :documents

        # cache_sweeper :my_page_others_documents_sweeper

        helper :easy_query
        include EasyQueryHelper
        helper :sort
        include SortHelper
        helper :documents
        include DocumentsHelper
        helper :custom_fields
        include CustomFieldsHelper

        alias_method_chain :index, :easy_extensions
        alias_method_chain :create, :easy_extensions
        alias_method_chain :edit, :easy_extensions
        alias_method_chain :update, :easy_extensions
        alias_method_chain :add_attachment, :easy_extensions
        alias_method_chain :destroy, :easy_extensions

        def csv
          return true unless request.format == :csv
          query     = EasyDocumentQuery.new(:name => '_')
          documents = @project.documents.preload([:attachments, :category]).to_a.select { |x| x.respond_to?(:active_record_restricted?) ? !x.active_record_restricted?(User.current, :read) : true }

          send_data(documents_to_csv(documents, query), :filename => get_export_filename(:csv, query))
        end

      end
    end

    module InstanceMethods

      def mark_as_read
        @document.mark_as_read if @document && !@document.new_record?
      end

      def index_with_easy_extensions
        @sort_by = %w(category date title author).detect { |i| i == params[:sort_by] } || 'category'

        @document = @project.documents.build


        # limit = 3 #per_page_option
        documents = @project.documents.preload(:attachments, :category).order(title: :asc)
        # documents = documents.select{|x| x.respond_to?(:active_record_restricted?) ? !x.active_record_restricted?(User.current, :read) : true}

        # @document_count = documents.count
        # @document_pages = Redmine::Pagination::Paginator.new @document_count, limit, params[:page]
        # offset = @document_pages.offset

        count, @grouped = EasyDocumentQuery.filter_non_restricted_documents(documents, User.current, 0, @sort_by || '')

        call_hook(:easy_controller_documents_index, { :params => params, :project => @project })

        # if request.xhr? && @document_pages.last_page.to_i < params['page'].to_i
        #   render_404
        #   return false
        # end

        respond_to do |format|
          format.html {
            render :layout => false if request.xhr? && !@query
          }
          format.api
        end
      end

      def create_with_easy_extensions
        @document = @project.documents.build
        @document.safe_attributes = params[:document]
        @document.save_attachments(params[:attachments])
        if @document.save
          respond_to do |format|
            format.html {
              render_attachment_warning_if_needed(@document)
              flash[:notice] = l(:notice_successful_create)
              redirect_to project_documents_path(@project)
            }
            format.api { render :action => 'show' }
          end
        else
          respond_to do |format|
            format.html { render :action => 'new' }
            format.api  { render_validation_errors(@document) }
          end
        end
      end

      def edit_with_easy_extensions
        @categories               = DocumentCategory.active
        @document.safe_attributes = params[:document]
        if request.post? and @document.save
          flash[:notice] = l(:notice_successful_update)
          redirect_to :controller => 'documents', :project_id => @project
        end
      end
    
      def update_with_easy_extensions
        @document.safe_attributes = params[:document]
        if @document.save
          respond_to do |format|
            format.html {
              flash[:notice] = l(:notice_successful_update)
              redirect_to document_path(@document)
            }
            format.api { render_api_ok }
          end
        else
          respond_to do |format|
            format.html { render :action => 'edit' }
            format.api  { render_validation_errors(@document) }
          end
        end
      end

      def add_attachment_with_easy_extensions
        attachments = Attachment.attach_files(@document, params[:attachments])
        render_attachment_warning_if_needed(@document)

        files = attachments[:files] + attachments[:new_versions]
        Mailer.deliver_attachments_added(files) if !@project.is_planned && attachments.present? && files.present? && Setting.notified_events.include?('document_added')

        redirect_to :controller => 'documents', :project_id => @project
      end

      def destroy_with_easy_extensions
        @document.destroy if request.delete?
        respond_to do |format|
          format.html { redirect_back_or_default (back_url || project_documents_path(@project)) }
          format.api  { render_api_ok }
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'DocumentsController', 'EasyPatch::DocumentsControllerPatch'
