class BudgetsheetController < ApplicationController

  before_action :authorize_global, only: [:index, :find_by_worker]

  accept_api_auth :index

  helper :sort
  include SortHelper
  helper :issues
  include IssuesHelper
  helper :easy_query
  include EasyQueryHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :timelog
  include TimelogHelper

  EasyExtensions::EasyPageHandler.register_for(self, {
    page_name: 'payroll-and-invoicing-sheet',
    path: proc { overview_budgetsheet_path(t: params[:t]) },
    show_action: :overview,
    edit_action: :overview_layout
  })

  def index
    retrieve_query(EasyBudgetSheetQuery)
    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)

    @easy_query_name = l(:budgetsheet_title)

    if params[:query_by_user] && params[:user_id]
      @query.remove_user_column
      @easy_query_name = User.find(params[:user_id]).name
    end

    @time_entries = prepare_easy_query_render
    if request.xhr? && !@time_entries
      render_404
      return false
    end

    respond_to do |format|
      format.html { render_easy_query_html }
      format.api
      format.csv  { send_data(export_to_csv(@time_entries, @query), :filename => get_export_filename(:csv, @query)) }
      format.pdf  { render_easy_query_pdf }
      format.xlsx { render_easy_query_xlsx }
    end
  end

  def find_by_worker
    @users = User.easy_budgetsheet_available_users.easy_type_internal
    @users = @users.like(params[:q]) unless params[:q].blank?

    respond_to do |format|
      format.html {render :partial => 'find_by_worker_list', :locals => {:users => @users}}
      format.js
    end
  end

  private

  def find_project
    @project = Project.find(params[:id])
  end

end
