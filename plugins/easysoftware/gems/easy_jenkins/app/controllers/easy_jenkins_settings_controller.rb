class EasyJenkinsSettingsController < ApplicationController
  menu_item :easy_jenkins

  helper :projects
  helper :easy_setting
  include EasySettingHelper

  before_action :find_project, only: [:project_settings]
  before_action :find_project_by_project_id, only: [:create, :update, :autocomplete_issues, :autocomplete_jobs, :test_connection]
  before_action :authorize
  before_action :load_easy_jenkins_setting, only: [:update]

  protect_from_forgery except: :test_connection

  def create
    @easy_jenkins_setting = EasyJenkins::Setting.new(resource_params)
    @easy_jenkins_setting.project = @project

    if @easy_jenkins_setting.save
      flash[:notice] = l('easy_jenkins.create_success')
    else
      flash[:notice] = l('easy_jenkins.create_error')
    end

    redirect_back_or_default project_easy_jenkins_settings_path(@project)
  end

  def update
    if @easy_jenkins_setting.update(resource_params)
      flash[:notice] = l('easy_jenkins.update_success')
    else
      flash[:notice] = l('easy_jenkins.update_error')
    end

    redirect_back_or_default project_easy_jenkins_settings_path(@project)
  end

  def autocomplete_issues
    render json: @project.issues.visible.pluck(:subject, :id)
  end

  def autocomplete_jobs
    render json: EasyJenkins::Api::Request.call(setting: @project.easy_jenkins_setting).fetch_jobs
  end

  def project_settings
    Rys::Feature.on('easy_jenkins.project.render_tab') do
      params[:tab] = 'easy_jenkins'

      @easy_jenkins_setting = EasyJenkins::Setting.find_or_initialize_by(project: @project)
    end
  end

  def test_connection
    setting = EasyJenkins::Setting.new(url: params[:url], user_name: params[:user_name], user_token: params[:user_token])
    connected = EasyJenkins::Api::Request.call(setting: setting).connected?
    @notice = connected ? l('easy_jenkins.connection_success') : l('easy_jenkins.connection_failure')
  end

  private

  def resource_params
    params.require(:easy_jenkins_setting).permit(:url, :user_name, :user_token, pipelines_attributes: [:id, :for_all_tasks, :name, :external_name, :_destroy, issue_ids: [], tracker_ids: [], status_ids: []])
  end

  def load_easy_jenkins_setting
    @easy_jenkins_setting = EasyJenkins::Setting.find(params[:id])
  end
end
