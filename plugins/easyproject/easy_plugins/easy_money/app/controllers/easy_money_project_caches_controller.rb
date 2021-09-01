class EasyMoneyProjectCachesController < ApplicationController

  menu_item :easy_money

  before_action :authorize_global

  accept_api_auth :index

  helper :easy_query
  include EasyQueryHelper
  helper :easy_money
  include EasyMoneyHelper
  helper :projects
  include ProjectsHelper
  helper :sort
  include SortHelper

  def index
    retrieve_query(EasyMoneyProjectCacheQuery)
    sort_init(@query.sort_criteria.empty? ? [['lft', 'asc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    prepare_easy_query_render

    if request.xhr? && !@entities
      render_404
      return false
    end

    respond_to do |format|
      format.html { render_easy_query_html }
      format.csv  { send_data(export_to_csv(@entities, @query), :filename => get_export_filename(:csv, @query, l(:label_easy_money_project_cache)))}
      format.pdf  {
        label = l(:label_easy_money_project_cache)
        send_file_headers! :type => 'application/pdf', :filename => get_export_filename(:pdf, @query, label)
        render 'easy_money_base_items/index', default_title: label
      }
      format.xlsx { send_data(export_to_xlsx(@entities, @query, :default_title => l(:label_easy_money_project_cache)), :filename => get_export_filename(:xlsx, @query, l(:label_easy_money_project_cache)))}
      format.api
    end
  end

end
