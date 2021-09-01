class EasyPrintableTemplatesController < ApplicationController

  before_action :authorize_global
  before_action :find_easy_printable_template, :except => [:index, :new, :create, :template_chooser]
  before_action :find_copy_from, :only => [:new]
  before_action :find_project_by_project_id, only: [:generate_docx_from_attachment]

  helper :queries
  include QueriesHelper
  helper :easy_query
  include EasyQueryHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :sort
  include SortHelper

  def index
    index_for_easy_query EasyPrintableTemplateQuery, [['project', 'asc']]
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def new
    @easy_printable_template = EasyPrintableTemplate.new
    if @copy_from
      @easy_printable_template.attributes = @copy_from.attributes.dup.except('id', 'internal_name', 'created_on', 'updated_on')
    end
    @easy_printable_template.safe_attributes = params[:easy_printable_template] if params[:easy_printable_template]

    @easy_printable_template.easy_printable_template_pages.build if @easy_printable_template.easy_printable_template_pages.empty?

    respond_to do |format|
      format.html
    end
  end

  def create
    @easy_printable_template = EasyPrintableTemplate.new
    @easy_printable_template.safe_attributes = params[:easy_printable_template] if params[:easy_printable_template]
    @easy_printable_template.save_attachments(params[:attachments]) if params[:attachments]

    if @easy_printable_template.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          if params[:continue_to] == 'preview'
            redirect_to(:action => 'preview', :id => @easy_printable_template, :back_url => params[:back_url], :entity_type => params[:entity_type], :entity_id => params[:entity_id])
          else
            redirect_back_or_default(:action => 'index')
          end
        }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    @easy_printable_template.safe_attributes = params[:easy_printable_template] if params[:easy_printable_template]
    @easy_printable_template.save_attachments(params[:attachments]) if params[:attachments]

    if @easy_printable_template.editable? && @easy_printable_template.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          if params[:continue_to] == 'preview'
            redirect_to(:action => 'preview', :id => @easy_printable_template, :back_url => params[:back_url], :entity_type => params[:entity_type], :entity_id => params[:entity_id])
          else
            redirect_back_or_default(:action => 'index')
          end
        }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
      end
    end
  end

  def destroy
    @easy_printable_template.destroy if @easy_printable_template.deletable?

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default(:action => 'index')
      }
    end
  end

  def template_chooser
    params.delete(:query_id) # TODO see easy_other_formats_builder.rb & _easy_query_export_format_links.html.erb
    retrieve_query(EasyPrintableTemplateQuery)
    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)
    @query.filters = @query.default_filter
    @query.group_by = :category_caption
    @query.load_groups_opened = false
    @query.column_names = %w(name description author)
    prepare_easy_query_render

    respond_to do |format|
      format.js
    end
  end

  def copy_with_pages
    @easy_printable_template = @easy_printable_template.dup_with_pages
    @continue_to = 'preview'
    respond_to do |format|
      format.html { render :action => 'new' }
    end
  end

  def preview
    create_variables_for_pdf(params)
    @pages_orientation = params[:pages_orientation] || @easy_printable_template.pages_orientation
    @pages_size = params[:pages_size] || @easy_printable_template.pages_size

    # 20 is added because of padding
    @pages_height = (params[:pages_height].presence || 1_000).to_i
    @pages_width = (params[:pages_width].presence || 1_000).to_i

    respond_to do |format|
      format.html {
        render layout: 'easy_printable_template_preview',
               only_path: false,
               locals: { pages_size: @pages_size,
                         pages_orientation: @pages_orientation,
                         pages_height: @pages_height,
                         pages_width: @pages_width }
      }
    end
  end

  def save_to_pdf
    create_variables_for_pdf

    filename = "#{format_date(Date.today)} - #{@easy_printable_template.name}.pdf"
    hook_options = {entity: @entity, filename: filename, options: {filename: filename, pdfkit_options: {}}}
    call_hook(:controller_easy_printable_templates_preview, hook_options)

    respond_to do |format|
      format.pdf do
        pdf = prepare_pdf_from_template(hook_options[:options][:pdfkit_options])

        send_data(pdf, :filename => hook_options[:options][:filename])
      end
    end
  end

  def save_to_document
    document = Document.where(:id => params[:document_id]).first

    create_variables_for_pdf(params[:serializable_attributes])

    if (document && create_pdf_attachment(document)) && document.save
      flash[:notice] = l(:notice_successful_create)
      path = document_path(document)
    else
      flash[:error] = l(:notice_failed_to_update)
      path = documents_path
    end
    redirect_back_or_default(path)
  end

  def save_to_attachment
    create_variables_for_pdf

    if @entity && create_pdf_attachment(@entity)
      flash[:notice] = l(:notice_successful_create)
    else
      flash[:error] = l(:notice_failed_to_update)
    end

    redirect_back_or_default({:action => 'index'})
  end

  def generate_docx_from_attachment
    template = @easy_printable_template.docx_template
    return unless template
    docx = EasyPrintableDocx::Document.open(template.diskfile)
    attachment = docx.generate(template, @project, view_context)

    if attachment
      send_file attachment.diskfile, filename: attachment.filename
    else
      render_404
    end
  end

  private

  def find_easy_printable_template
    @easy_printable_template = EasyPrintableTemplate.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def create_variables_for_pdf(params_hash = nil)
    params_hash ||= params
    @entity = nil
    if params_hash[:project_id].present?
      @project = begin; Project.find(params_hash[:project_id]); rescue; end;
    end
    if params_hash[:entity_type] && klass = (begin; params_hash[:entity_type].to_s.constantize; rescue; nil; end)
      if params_hash[:entity_id].present?
        begin
          @entity = klass.find(params_hash[:entity_id])
          @entity.project = @project if @project && @entity.respond_to?(:project)
        rescue StandardError => ex
          logger.error("EasyPrintableTemplatesController->preview: #{ex.message.to_s}") if logger
        end
      elsif klass < EasyQuery && params_hash[:entity_settings]
        begin
          deserialized_settings = HashWithIndifferentAccess.new(Rack::Utils.parse_nested_query(CGI.unescape(params_hash[:entity_settings])))
          @entity = klass.new
          @entity.project = @project
          @entity.from_params(deserialized_settings)
          @entity.add_statement_limitation_to_ids(params_hash[:selected_ids]) if params_hash[:selected_ids].present?
        rescue StandardError => ex
          logger.error("EasyPrintableTemplatesController->preview: #{ex.message.to_s}") if logger
        end
      end
    end

    if params_hash['page_content'] && @easy_printable_template
      params_hash['page_content'].each do |page_content_id, value|
        page = @easy_printable_template.easy_printable_template_pages.detect{|x| x.id == page_content_id.sub(/page_content_/, '').to_i}
        page.page_text = value if page
      end
    end
  end

  def find_copy_from
    @copy_from = EasyPrintableTemplate.find(params[:copy_from]) if params[:copy_from]
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
