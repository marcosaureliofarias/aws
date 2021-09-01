class AlertReportsController < ApplicationController

  before_action :find_report, :only => [:show, :edit, :update, :destroy, :archive_report, :unarchive_report]
  before_action :find_alert, :only => [:alert]
  before_action :authorize_global

  helper :sort
  include SortHelper

  # GET /alert_types
  def index
    sort_init 'alerttype', 'asc'
    sort_update	'alerttype' => "#{Alert.table_name}.position ASC"

    if (params[:type_id])
      @reports = AlertReport.visible.by_type(params[:type_id]).sorted
    elsif (params[:alert_id])
      @reports = Alert.find(params[:alert_id]).reports.sorted
    end

    @reports ||= AlertReport.visible.sorted

    @reports_count = @reports.count
    @reports_pages = Redmine::Pagination::Paginator.new @reports_count, 40, params['page']

    if request.xhr? && @reports_pages.last_page.to_i < params['page'].to_i
      render_404
      return false
    end

    @reports = @reports.joins(:alert).preload(:alert).limit(@reports_pages.per_page).offset(@reports_pages.offset).order(sort_clause)

    respond_to do |format|
      format.html { render :action => 'index', :layout => false if request.xhr? }
      # format.atom { render_feed(@reports, :title => "titulek...") }
    end
  end

  # GET /alert_context/:id
  # GET /alert_context/:id/show
  def show
  end

  # GET /alert_context/new
  def new
  end

  # POST /alert_context
  def create
  end

  # GET /alert_context/:id/edit
  def edit
  end

  # PUT /alert_context/:id
  def update
  end

  # DELETE /alert_context/:id
  def destroy
  end

  def alert
    @reports = @alert.reports
  end

  def archive_report
    @report.archived = true

    respond_to do |format|
      if @report.save
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_back_or_default( :action => 'index' ) }
      else
        format.html { redirect_back_or_default( :action => 'index' ) }
      end
    end
  end

  def unarchive_report
    @report.archived = false

    respond_to do |format|
      if @report.save
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_back_or_default( :action => 'archive' ) }
      else
        format.html { redirect_back_or_default( :action => 'archive' ) }
      end
    end
  end

  def archive
    sort_init 'alerttype', 'asc'
    sort_update	'alerttype' => "#{Alert.table_name}.position ASC"

    @reports = AlertReport.archived

    @reports_count = @reports.size
    @reports_pages = Redmine::Pagination::Paginator.new @reports_count, per_page_option, params['page']

    @reports = @reports.joins(:alert).preload(:alert).order(sort_clause).limit(@reports_pages.per_page).offset(@reports_pages.offset)
  end


private

  def find_report
    @report = AlertReport.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_alert
    @alert = Alert.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
