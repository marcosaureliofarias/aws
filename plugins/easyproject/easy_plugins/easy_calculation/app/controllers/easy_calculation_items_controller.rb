class EasyCalculationItemsController < ApplicationController
  before_action :find_easy_calculation_item, except: [:add_issue, :remove_issue]
  before_action :find_issue_item, only: [:add_issue, :remove_issue]
  before_action :find_project_for_calculation, except: [:add_issue, :remove_issue]
  before_action :authorize, except: [:add_issue, :remove_issue]
  before_action :authorize_global, only: [:add_issue, :remove_issue]

  def create
    @item = EasyCalculationItem.new
    @item.safe_attributes = params[:easy_calculation_item]
    @item.project = @project
    respond_to do |format|
      format.api do
        if @item.save
          render_api_ok
        else
          render_validation_errors(@item)
        end
      end
    end
  end

  def edit
    render :partial => 'form', :locals => {:item => @item}
  end

  def update
    @item.safe_attributes = params[:easy_calculation_item]
    respond_to do |format|
      format.api do
        if @item.save
          render_api_ok
        else
          render_validation_errors(@item)
        end
      end
    end
  end

  def destroy
    @item.destroy

    respond_to do |format|
      format.api { render_api_ok }
    end
  end

  def add_issue
    @issue.add_to_easy_calculations

    respond_to do |format|
      format.js
      format.api { render_api_ok }
    end
  end

  def remove_issue
    @issue.remove_from_easy_calculations

    respond_to do |format|
      format.api { render_api_ok }
    end
  end

  private

  def find_easy_calculation_item
    @item = EasyCalculationItem.find(params[:id]) if params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project_for_calculation
    @project = @item.try(:project)
    @project ||= Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_issue_item
    @issue = Issue.find(params[:id]) if params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
