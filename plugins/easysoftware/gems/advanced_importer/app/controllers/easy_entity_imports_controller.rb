class EasyEntityImportsController < ApplicationController
  before_action :require_admin
  before_action :init_new_import, only: [:new, :create]
  before_action :find_entity, except: [:index, :new, :create, :fetch_preview, :import, :destroy_import_attribute]
  before_action :find_easy_entity_import_for_import, only: [:fetch_preview, :import]

  helper :custom_fields, :easy_query, :sort
  include SortHelper
  include EasyQueryHelper

  def index
    index_for_easy_query EasyEntityImportQuery
  end

  def new
    @available_entity_types = @easy_entity_import.get_available_entity_types
    call_hook(:controller_easy_entity_imports_action_new, { easy_entity_import: @easy_entity_import, available_entity_types: @available_entity_types })
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @easy_entity_import.safe_attributes = params[:easy_entity_import]

    respond_to do |format|
      if @easy_entity_import.save
        format.html { redirect_back_or_default(easy_entity_import_path(@easy_entity_import), notice: l(:notice_successful_create)) }
      else
        @available_entity_types = @easy_entity_import.get_available_entity_types
        format.html { render(action: 'new') }
      end
    end
  end

  def edit
    @available_entity_types = @easy_entity_import.get_available_entity_types
    respond_to do |format|
      format.html
    end
  end

  def update
    @easy_entity_import.safe_attributes = params[:easy_entity_import]

    respond_to do |format|
      if @easy_entity_import.save
        format.html { redirect_back_or_default(easy_entity_imports_path, notice: l(:notice_successful_update)) }
      else
        format.html { render(action: 'edit') }
      end
    end
  end

  def destroy
    @easy_entity_import.destroy

    respond_to do |format|
      format.html { redirect_back_or_default(easy_entity_imports_path, notice: l(:notice_successful_delete)) }
    end
  end

  def show
    respond_to do |format|
      format.html
    end
  end


  # ===========

  def fetch_preview
    if (file_or_url = @easy_entity_import.attachments.first || @easy_entity_import.api_url)
      @file = @easy_entity_import.preview_for_file(file_or_url)
    end

    @processed = true
    respond_to do |format|
      format.html { render(action: 'show') }
      format.js
    end
  rescue StandardError => e
    respond_to do |format|
      @error = e.message
      format.html { request.xhr? ? render(plain: e.message) : raise(e) }
      format.js
    end
  end

  def assign_import_attribute
    # assignment = @easy_entity_import.easy_entity_import_attributes_assignments.where(:entity_attribute => params[:entity_attribute]).first
    unsafe_params = params.to_unsafe_hash
    entity_attribute = unsafe_params[:entity_attribute]
    @easy_entity_import_attributes_assignment = @easy_entity_import.assign_import_attributes(unsafe_params[:entity_attribute], unsafe_params[:easy_entity_import_attribute][entity_attribute])
    if @easy_entity_import_attributes_assignment.save
      @saved = true
    else
      @saved = false
    end

    respond_to do |format|
      # format.html {render(:action => 'show')}
      format.js
    end
  end

  def generate_xml
    respond_to do |format|
      format.xml { send_data(@easy_entity_import.transform_xml.to_xml, filename: 'easy_xml.xml') }
    end
  end

  def generate_xslt
    doc = @easy_entity_import.get_xslt
    respond_to do |format|
      format.xml { send_data(doc, filename: 'easy_xslt.xml') }
    end
  end

  def import
    @attachment = Attachment.find(params[:attachment_id]) if params[:attachment_id].present?

    if @attachment
      File.open(@attachment.diskfile) do |f|
        @output = @easy_entity_import.import(f)
      end
      @processed = true
    elsif @easy_entity_import.attachments.any?
      @processed = false
      # prepare ajax per file loader
    else
      @output = @easy_entity_import.import_importer
      @processed = true
    end

    respond_to do |format|
      format.html
      format.js
    end
  rescue StandardError => e
    @error = e.message
    Rails.logger.error(@error)
    Rails.logger.error(e.backtrace.join("\n").to_s)
    respond_to do |format|
      format.html { render(plain: e.message) }
      format.js
    end
  end

  def destroy_import_attribute
    @easy_entity_import_attributes_assignment = EasyEntityImportAttributesAssignment.find(params[:id])
    @easy_entity_import_attributes_assignment.destroy
    respond_to do |format|
      format.html
      format.js
    end
  end


  private

  def find_easy_entity_import_for_import
    @easy_entity_import = EasyEntityImport.preload(:easy_entity_import_attributes_assignments).find_by(id: params[:id])
    @easy_entity_import.safe_attributes = params[:easy_entity_import]
    @easy_entity_import.api_url = params[:api_url]
    # 'save_attachments' saves only attachments without container.
    # Since these attachments might already be saved it will cause a validation error preventing import save
    @easy_entity_import.save_attachments(parsed_attachments_from_params) if parsed_attachments_from_params.present?
    @easy_entity_import.save
  end

  def init_new_import
    klass = EasyEntityImport.available_import_entities.detect { |klass| klass.name == params[:type] }

    if klass.nil?
      render_404(message: :error_easy_entity_imports_new_import_type_not_found)
    else
      @easy_entity_import = klass.new
    end
  end

  def find_entity
    @easy_entity_import = EasyEntityImport.preload(:easy_entity_import_attributes_assignments).find(params[:id])
    return render_404 if @easy_entity_import.class.disabled?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Removes attachments that are already saved and assigned to a container from params
  def parsed_attachments_from_params
    return unless (attachments = params[:attachments])

    attachments.delete_if {|_key, value| Attachment.find_by_token(value[:token]).nil? }
    attachments
  end

end
