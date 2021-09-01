class EasyChecklistItemsController < ApplicationController

  before_action :find_easy_checklist
  before_action :find_easy_checklist_item, :except => [:new, :create]

  before_action :set_project_for_authorization
  # only for templates
  before_action :authorize_global, :if => Proc.new { @project.blank? }
  before_action :authorize, :if => Proc.new { @project.present? }

  def new
    @easy_checklist_item = EasyChecklistItem.new

    respond_to do |format|
      format.js
    end
  end

  def create
    @easy_checklist_item = @easy_checklist.easy_checklist_items.build
    @easy_checklist_item.safe_attributes = params[:easy_checklist_item]
    @easy_checklist_item.author = User.current

    @easy_checklist_item.save

    respond_to do |format|
      format.js
      format.json { render json: @easy_checklist_item }
    end
  end

  def update
    # check/uncheck
    # set only if params[:done] present, otherwise the request is from inline edit
    @easy_checklist_item.done = (params[:done] == '1') if @easy_checklist_item.can_change? && params[:done]
    # inline edit
    @easy_checklist_item.safe_attributes = params[:easy_checklist_item] if params[:easy_checklist_item]
    @easy_checklist_item.save
    respond_to do |format|
      format.js
      format.json { render json:  @easy_checklist_item }
      format.api { render_api_ok }
    end
  end

  def destroy
    @easy_checklist_item.destroy

    respond_to do |format|
      format.js
      format.json { render_api_head :no_content }
    end
  end

  private

  def find_easy_checklist
    @easy_checklist = EasyChecklist.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_easy_checklist_item
    @easy_checklist_item = EasyChecklistItem.find(params[:easy_checklist_item_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def set_project_for_authorization
    @project = @easy_checklist.entity.try(:project)
  end
end
