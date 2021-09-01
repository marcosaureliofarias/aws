class EasyEarnedValuesController < ApplicationController
  menu_item :easy_earned_values

  before_action :find_easy_earned_value, only: [:show, :edit, :update, :destroy]
  before_action :find_project
  before_action :authorize

  def index
    default_id = EasyEarnedValue.where(project: @project, project_default: true).limit(1).pluck(:id).first
    if default_id
      redirect_to easy_earned_value_path(default_id)
    else
      load_project_earned_values
    end
  end

  def show
    load_project_earned_values
  end

  def new
    @easy_earned_value = EasyEarnedValue.new(project: @project)
    load_project_baselines
  end

  def edit
    load_project_baselines
  end

  def create
    @easy_earned_value = EasyEarnedValue.new
    @easy_earned_value.type = params[:easy_earned_value] && params[:easy_earned_value][:type]
    @easy_earned_value.project = @project
    @easy_earned_value.safe_attributes = params[:easy_earned_value]

    respond_to do |format|
      format.html {
        if @easy_earned_value.save
          redirect_back_or_default settings_project_path(@project, 'easy_earned_values')
        else
          load_project_baselines
          render :new
        end
      }
    end
  end

  def update
    @easy_earned_value.safe_attributes = params[:easy_earned_value]

    respond_to do |format|
      format.html {
        if @easy_earned_value.save
          redirect_back_or_default settings_project_path(@project, 'easy_earned_values')
        else
          load_project_baselines
          render :edit
        end
      }
    end
  end

  def destroy
    @easy_earned_value.destroy

    redirect_back_or_default settings_project_path(@project, 'easy_earned_values')
  end

  private

    def find_project
      if params[:project_id]
        @project = Project.find(params[:project_id])
      elsif @easy_earned_value
        @project = @easy_earned_value.project
      end
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def find_easy_earned_value
      @easy_earned_value = EasyEarnedValue.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def load_project_baselines
      @baselines = Project.where(easy_baseline_for: @project).reorder(:updated_on)
    end

    def load_project_earned_values
      @easy_earned_values = EasyEarnedValue.where(project: @project).reorder(:updated_at).reverse_order
    end

end
