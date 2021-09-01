class EasyChartBaselinesController < ApplicationController

  before_action :find_page_module, only: [:index, :create]
  before_action :find_chart_baseline, only: [:show, :destroy]

  accept_api_auth :index, :show, :create, :destroy

  def index
    @chart_baselines = EasyChartBaseline.where(page_module: @page_module).order(updated_at: :desc)
    respond_to do |format|
      format.json { render json: @chart_baselines.collect { |chbl| { id: chbl.id, name: chbl.name, date: chbl.updated_at.to_date } } }
    end
  end

  def show
    # before_action find_chart_baseline
    if @chart_baseline.options && @chart_baseline.options[:axis]
      @chart_baseline.options[:axis][:rotated] = @chart_baseline.options[:axis][:rotated].to_boolean
    end

    respond_to do |format|
      format.json {
        render json: {
            name:          @chart_baseline.name,
            date:          @chart_baseline.updated_at.to_date,
            data:          @chart_baseline.data,
            ticks:         @chart_baseline.ticks,
            chart_options: @chart_baseline.options
        }
      }
    end
  end

  def create
    @chart_baseline                 = EasyChartBaseline.new
    @chart_baseline.safe_attributes = params[:easy_chart_baseline]
    @chart_baseline.page_module     = @page_module
    @chart_baseline.name            ||= @page_module.settings['query_name'] if @page_module.settings['query_type'] == '2'
    @chart_baseline.name            ||= EasyQuery.where(id: @page_module.settings['query_id']).pluck(:name).first if @page_module.settings['query_type'] == '1'
    respond_to do |format|
      if @chart_baseline.save
        format.json { render json: {
            id:            @chart_baseline.id,
            name:          @chart_baseline.name,
            date:          @chart_baseline.updated_at.to_date
          }, status: :created }
      else
        format.json { render json: { errors: @model.errors.full_messages }, status: 422 }
      end
    end
  end

  def destroy
    @chart_baseline.destroy

    respond_to do |format|
      format.json { render_api_ok }
    end
  end

  private

  def find_page_module
    at           = EasyPageZoneModule.arel_table
    @page_module = EasyPageZoneModule.where(at[:user_id].eq(User.current.id).or(at[:user_id].eq(nil))).find(params[:module_uuid])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_chart_baseline
    @chart_baseline = EasyChartBaseline.visible.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
