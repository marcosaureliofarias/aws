class EasyMoneyCashFlowController < ApplicationController
  menu_item :easy_money

  before_action :authorize_global

  helper :easy_query
  include EasyQueryHelper
  helper :easy_money
  include EasyMoneyHelper
  helper :projects
  include ProjectsHelper
  helper :sort
  include SortHelper

  def index
    retrieve_query(EasyMoneyCashFlowQuery)
    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)
    @query.add_filter('project_id', '=', ['mine']) if !@query.has_filter?('project_id') && User.current.logged?

    prepare_easy_query_render(@query, { limit: nil })

    if request.xhr? && !@entities
      render_404
      return false
    end

    respond_to do |format|
      format.html { render_easy_query } # format.html { render_easy_query_html }
      #format.csv  { send_data(export_to_csv(@entities, @query), :filename => get_export_filename(:csv, @query, l(:label_easy_money_cash_flow)))}
      #format.pdf  { send_file_headers! :type => 'application/pdf', :filename => get_export_filename(:pdf, @query, l(:label_easy_money_cash_flow)) }
      format.xlsx { send_data(export_to_xlsx(@entities, @query, caption: :label_easy_money_cash_flow), filename: "#{l(:label_easy_money_cash_flow)}.xlsx")}
    end
  end

end if Redmine::Plugin.installed?(:easy_money)
