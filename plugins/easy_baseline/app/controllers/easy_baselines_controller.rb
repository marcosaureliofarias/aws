class EasyBaselinesController < ApplicationController
  accept_api_auth :index, :create, :destroy

  before_action :find_project_by_project_id
  before_action :authorize
  before_action :authorize_baseline_source

  include Redmine::I18n
  include SortHelper

  def index
    @baselines = Project.where(easy_baseline_for: @project)
  end

  def new
    options = {}
    options[:name] = params[:easy_baseline][:name] if params[:easy_baseline]
    @baseline = @project.create_baseline_from_project(options)
  end

  def create
    options = {}
    options[:name] = params[:easy_baseline][:name] if params[:easy_baseline]

    CreateEasyBaselineJob.perform_later(@project, User.current, options)

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_create_baseline_in_the_background)
        redirect_back_or_default project_easy_baselines_path(@project)
      }
      format.api  { render_api_ok }
    end
  end

  def destroy
    @baseline = Project.find(params[:id])
    @baseline.destroy

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default project_easy_baselines_path(@project)
      }
      format.api { head :no_content }
    end
  end

  private

  def authorize_baseline_source
    render_404 unless @project.easy_baseline_for.nil?
  end

end
