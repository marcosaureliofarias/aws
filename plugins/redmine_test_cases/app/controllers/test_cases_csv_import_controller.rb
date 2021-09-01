class TestCasesCsvImportController < ApplicationController
  before_action :authorize_global
  before_action :validate_params, only: [:create, :update]
  before_action :init_new_import, only: [:new, :create]
  before_action :find_entity, except: [:index, :new, :create, :fetch_preview, :import, :destroy_import_attribute]
  before_action :find_easy_entity_import_for_import, only: [:fetch_preview, :import]

  helper :custom_fields, :easy_query, :sort
  include SortHelper
  include EasyQueryHelper

  def index
    index_for_easy_query TestCaseCsvImportQuery
  end

  def new
    @available_entity_types = @easy_entity_import.get_available_entity_types
    call_hook(:controller_test_cases_csv_import_action_new, { easy_entity_import: @easy_entity_import, available_entity_types: @available_entity_types })
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @easy_entity_import.safe_attributes = params[:easy_test_case_csv_import]

    respond_to do |format|
      if @easy_entity_import.save
        format.html { redirect_back_or_default(test_cases_csv_import_path(@easy_entity_import), notice: l(:notice_successful_create)) }
      else
        @available_entity_types = @easy_entity_import.get_available_entity_types
        format.html { render(action: 'new') }
      end
    end
  end

  def update
    @easy_entity_import.safe_attributes = params[:easy_test_case_csv_import]

    respond_to do |format|
      if @easy_entity_import.save
        format.html { redirect_back_or_default(test_cases_csv_import_index_path, notice: l(:notice_successful_update)) }
      else
        format.html { render(action: 'edit') }
      end
    end
  end

  def destroy
    @easy_entity_import.destroy

    respond_to do |format|
      # format.html { redirect_back_or_default(test_cases_csv_import_index_path, notice: l(:notice_successful_delete)) }
      format.html { redirect_to test_cases_csv_import_index_path, notice: l(:notice_successful_delete), status: 303 }
    end
  end

  def edit
    @available_entity_types = @easy_entity_import.get_available_entity_types
    respond_to do |format|
      format.html
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
    return render_401 if @attachment && !@attachment.visible?(User.current)

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
    return render_404 if @easy_entity_import_attributes_assignment.class.name != test_case_csv_import_name
    @easy_entity_import_attributes_assignment.destroy
    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def validate_params
    render_403 if params[:type] != test_case_csv_import_name || params[:easy_test_case_csv_import][:entity_type] != "TestCase"
  end

  def find_easy_entity_import_for_import
    begin
      @easy_entity_import = get_entity
    rescue
      return render_404
    end

    @easy_entity_import.safe_attributes = params[:easy_test_case_csv_import]
    @easy_entity_import.api_url = params[:api_url]
    @easy_entity_import.save_attachments(params[:attachments])
    @easy_entity_import.save
  end

  def init_new_import
    @easy_entity_import = EasyTestCaseCsvImport.new
  end

  def find_entity
    @easy_entity_import = get_entity
  rescue
    render_404
  end

  def get_entity
    EasyTestCaseCsvImport.preload(:easy_entity_import_attributes_assignments).find(params[:id])
  end

  def test_case_csv_import_name
    'EasyTestCaseCsvImport'
  end

end
