class EasyEntityReplacableTokensController < ApplicationController

  before_action :get_variables

  def list
    respond_to do |format|
      format.js
    end
  end

  private

  def get_variables
    @entity_class = params[:entity_type].constantize if params[:entity_type]
    render_404 if @entity_class.nil?

    @project ||= Project.find(params[:project_id]) if params[:project_id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
