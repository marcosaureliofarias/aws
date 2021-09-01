require_relative 'concerns/easy_agile_controller_methods'

class EasyAgileDataController < ApplicationController

  before_action :find_project_by_project_id, if: proc { params[:project_id] && !params[:query_is_for_all] }

  include EasyQueryHelper
  include Concerns::EasyAgileControllerMethods

  def swimlane_values
    swimlane = params[:filter_name]
    return render_404 if swimlane.blank?

    add_easy_page_zone_module_data(params[:easy_page_zone_module_uuid])

    query_params = {
      query_param: params[:query_param],
      skip_project_cond: true,
      dont_use_project: params[:dont_use_project],
      modal_selector: params[:modul_uniq_id] == 'modal_selector'
    }
    retrieve_query(params[:type].safe_constantize, false, query_params)

    @values = get_values_for_swimlane(swimlane, @query)

    respond_to do |format|
      format.json { render json: @values }
    end
  end

end
