module Admin
  class EasySettingsController < ApplicationController

    accept_api_auth :show, :create, :update, :destroy

    skip_before_action :render_402, :render_307, :raise => false
    before_action :require_admin
    before_action :find_entity, only: [:show, :update, :destroy]

    def index
      head 406
    end

    def show
      respond_to do |format|
        format.any(:json, :xml) { render request.format.to_sym => @easy_setting }
      end
    end

    def create
      @easy_setting = EasySetting.new(params.require(:easy_setting).permit!)
      respond_to do |format|
        if @easy_setting.save
          format.api { render request.format.to_sym => @easy_setting, status: :created }
        else
          format.api { render_api_errors @easy_setting.errors.full_messages }
        end
      end
    end

    def update
      respond_to do |format|
        if @easy_setting.update_attributes(params.require(:easy_setting).permit!)
          format.api { render request.format.to_sym => @easy_setting }
        else
          format.api { render_api_errors @easy_setting.errors.full_messages }
        end
      end
    end

    def destroy
      @easy_setting.destroy
      respond_to do |format|
        format.any(:json, :xml) { render_api_ok }
      end
    end

    private

    def find_entity
      if /^\d+$/.match?(params[:id])
        @easy_setting = EasySetting.find(params[:id])
      elsif params[:project_id].present?
        @easy_setting = EasySetting.find_by!(name: params[:id], project_id: params[:project_id])
      else
        @easy_setting = EasySetting.find_by!(name: params[:id], project_id: nil)
      end
    rescue ActiveRecord::RecordNotFound
      render_404
    end

  end

end
