class EasyHelpdeskMailboxesController < ApplicationController
  layout 'admin'

  before_action :authorize_global
  before_action :find_easy_rake_task, :only => [:show, :edit, :update, :destroy]

  helper :easy_rake_tasks
  include EasyRakeTasksHelper

  def index
    @tasks = EasyRakeTaskEasyHelpdeskReceiveMail.all

    last_info_ids = EasyRakeTaskInfo.where(:easy_rake_task_id => @tasks).group(:easy_rake_task_id).maximum(:id).values
    @last_infos = EasyRakeTaskInfo.where(:id => last_info_ids).inject({}) { |var, info| var[info.easy_rake_task_id] = info; var }

    respond_to do |format|
      format.html
    end
  end

  private

  def find_easy_rake_task
    @task = EasyRakeTaskEasyHelpdeskReceiveMail.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
