class EasyResourceAvailabilitiesController < ApplicationController

  before_action :require_login

  EasyExtensions::EasyPageHandler.register_for(self, {
      page_name:   'easy-resource-booking-module',
      path:        proc { easy_resource_availabilities_path(t: params[:t]) },
      show_action: :index,
      edit_action: :layout
  })

  def update
    uuid           = params[:uuid]
    date           = params[:date].to_date
    hour           = params[:hour].blank? ? nil : params[:hour].to_i
    available      = !params[:available].blank?
    day_start_time = params[:day_start_time].to_i
    day_end_time   = params[:day_end_time].to_i
    description    = params[:description]

    available = EasyResourceAvailability.set_availability(uuid, date, hour, available, description, day_start_time, day_end_time)

    if available
      head :ok
    end
  end

end
