class EasyLightResourcesController < ApplicationController

  include_query_helpers
  helper :custom_fields
  helper :issues

  def index
    if User.current.allowed_to_globally?(:view_global_easy_gantt)
      index_for_easy_query EasyLightResourceQuery
    else
      render_403
    end
  end

end
