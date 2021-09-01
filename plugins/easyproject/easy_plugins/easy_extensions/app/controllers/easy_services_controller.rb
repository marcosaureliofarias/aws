class EasyServicesController < ApplicationController
  accept_api_auth :load_backgrounds

  EasyExtensions::EasyBackgroundService.services.each do |_, service|
    Array(service.includes.call).each do |klass|
      include(klass)
    end
  end

  def load_backgrounds
    @result = {}
    to_load = Array(params[:services]).map(&:to_sym)

    EasyExtensions::EasyBackgroundService.services.each do |name, service|
      next unless to_load.include?(name)
      next unless instance_eval(&service.active_if)

      @result[name] = instance_eval(&service.execution)
    end

    respond_to do |format|
      format.json { render json: @result }
    end
  end

end
