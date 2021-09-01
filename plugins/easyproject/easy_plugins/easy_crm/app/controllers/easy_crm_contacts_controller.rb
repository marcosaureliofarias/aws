class EasyCrmContactsController < ApplicationController

  menu_item :easy_crm

  before_action :check_contacts
  before_action :find_optional_project

  helper :easy_crm
  include EasyCrmHelper
  helper :easy_query
  include EasyQueryHelper
  helper :attachments
  include AttachmentsHelper
  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper

  def index
    retrieve_query(EasyCrmContactQuery)
    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)

    if request.xhr? && params[:easy_query_q]
    elsif params[:set_filter] != '1'
      @query.add_additional_statement("#{EasyContactEntityAssignment.table_name}.entity_type = 'EasyCrmCase' AND #{EasyContactEntityAssignment.table_name}.entity_id = #{EasyCrmCase.table_name}.id")
    end

    if @project && !@query.has_filter?('xproject_id')
      @query.add_short_filter('xproject_id', '=' + @project.id.to_s)
    end

    prepare_easy_query_render

    if request.xhr? && !@entities
      render_404
      return false
    end

    respond_to do |format|
      format.html {
        render_easy_query_html
      }
    end
  end

  private

  def check_contacts
    render_404 unless Object.const_defined?(:EasyContacts)
  end

  def find_optional_project
    @project = Project.find(params[:id]) if params[:id]
  end

end
