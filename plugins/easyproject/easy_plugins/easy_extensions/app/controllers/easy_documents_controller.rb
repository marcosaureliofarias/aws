class EasyDocumentsController < ApplicationController

  before_action :find_project_by_project_id, :only => [:select_project]

  helper :attachments
  include AttachmentsHelper
  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :documents
  include DocumentsHelper
  helper :custom_fields
  include CustomFieldsHelper

  default_search_scope :documents

  accept_api_auth :index

  def index
    retrieve_query(EasyDocumentQuery)
    @query.add_additional_statement(Project.arel_table[:easy_is_easy_template].eq(false).to_sql)
    @query.group_by = nil

    @sort_by = %w(category date title author project).detect { |i| i == params[:sort_by] } || 'category'

    prepare_easy_query_render

    if request.xhr? && !@entities
      render_404
      return false
    end

    @query.sort_criteria                                                                                                 = { '0' => ['project', 'asc'], '1' => ['', ''], '2' => ['', ''] } if @query.sort_criteria.blank?
    @query.display_filter_columns_on_index, @query.display_filter_group_by_on_index, @query.display_filter_sort_on_index = false, false, true
    @query.display_filter_columns_on_edit, @query.display_filter_group_by_on_edit, @query.display_filter_sort_on_edit    = false, false, true
    @query.display_filter_settings_on_edit, @query.display_filter_settings_on_index                                      = false, false
    @query.display_project_column_if_project_missing                                                                     = false

    respond_to do |format|
      format.html do
        free_text_search      = request.xhr? && params[:easy_query_q]
        @categories_documents = EasyDocumentQuery.filter_non_restricted_documents(@entities, User.current, @limit, @sort_by || '').last
        @query.export_formats.delete_if { |k, v| k != :csv }
        if free_text_search
          render partial: 'easy_documents/easy_documents'
        else
          render template: 'easy_documents/index'
        end
      end
      format.csv {
        @csv_entities = @entities[nil][:entities]
        send_data(documents_to_csv(@csv_entities, @query), :filename => get_export_filename(:csv, @query)) }
      format.api {
        @documents = @entities
      }
    end
  end

  def new
    @document = Document.new
    @project  = Project.find(params[:project_id]) unless params[:project_id].blank?
    @document = @project.documents.build if @project
    @projects = Project.non_templates.sorted.visible.has_module(:documents)
  end

  def select_project
    if @project
      @document = @project.documents.build
      respond_to do |format|
        format.js
      end
    else
      head :ok
    end
  end

  def new_attachments
    @document = Document.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

end
