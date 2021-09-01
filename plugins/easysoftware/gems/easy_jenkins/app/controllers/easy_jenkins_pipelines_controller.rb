class EasyJenkinsPipelinesController < ApplicationController
  helper :projects

  before_action :find_project_by_project_id, only: [:run, :history]
  before_action :find_issue_by_issue_id, only: [:run]
  before_action :authorize, except: [:update_queue]
  before_action :load_pipeline, only: [:run]

  protect_from_forgery except: :history

  JOB_STATE_MAPPER = {
    'FAILURE' => :failure,
    'SUCCESS' => :success
  }

  def run
    EasyJenkins::Api::Request.call(setting: @pipeline.setting).run_job(@pipeline, @issue)

    head :ok
  end

  def history
    @issue = Issue.find(params[:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def update_queue
    job = EasyJenkins::Job
      .joins(:pipeline)
      .where(queue_id: build_params['queue_id'], easy_jenkins_pipelines: { external_name: params[:name] })
      .first_or_create

    job.state = JOB_STATE_MAPPER[build_params['status']]
    job.url = build_params['full_url']
    job.result = build_params['log']
    job.save

    job.update_test_cases if Redmine::Plugin.installed?(:redmine_test_cases) && job.state && build_params['phase'] == 'FINALIZED'

    head :ok
  end

  private

  def build_params
    params.require(:build).permit!
  end

  def find_issue_by_issue_id
    @issue = Issue.find(params[:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def load_pipeline
    @pipeline =
      if params[:pipeline_id].present?
        EasyJenkins::Pipeline.find(params[:pipeline_id])
      else
        EasyJenkins::Pipeline.first
      end
  end
end
