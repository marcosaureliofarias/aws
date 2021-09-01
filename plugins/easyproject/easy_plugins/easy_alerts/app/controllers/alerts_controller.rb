class AlertsController < ApplicationController

  before_action :create_alert, :only => [:new, :create]
  before_action :find_alert, :only => [:show, :edit, :update, :destroy, :report]
  before_action :find_and_fill_alert, :only => [:context_changed, :rule_changed, :custom_action]
  before_action :set_settings, :only => [:new, :context_changed, :rule_changed]
  before_action :set_class_variables, :except => [:index, :report]
  before_action :authorize_global
  before_action :check_permission_manage_alerts_for_all, :only => [:update, :destroy]
  before_action :check_permission_generate_report, :only => [:report]

  helper :alerts
  include AlertsHelper
  helper :issues
  include IssuesHelper
  helper :timelog
  include TimelogHelper

  # GET /alerts
  def index
    scope = Alert.preload(:mail_group)
    if params[:for_all] == '1' && User.current.allowed_to?(:manage_alerts_for_all, nil, :global => true)
      @alerts = scope.for_all
    else
      @alerts = scope.user_alerts
    end
  end

  # GET /alerts/:id
  # GET /alerts/:id/show
  def show
    redirect_to( :action => 'edit' )
  end

  # GET /alerts/new
  def new
    @alert.type = AlertType.default
    @issue = Issue.find(params[:issue]) if params[:issue]
  end

  # POST /alerts
  def create
    @settings = params

    unless @alert.rule.nil?
      @alert.rule.initialize_settings(@settings)
      @alert.rule_settings = @alert.rule.serialize_settings(@settings)
      @alert.set_nextrun_at
    end

    respond_to do |format|
      if @alert.save
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to( :action => 'index' ) }
      else
        format.html { render :action => 'new' }
      end
    end
  end

  # GET /alerts/:id/edit
  def edit
    @settings = @alert.rule_settings
  end

  # PUT /alerts/:id
  def update
    @settings = params
    @alert.rule_settings = @alert.rule.serialize_settings(params) unless params[:reorder_to_position]

    @alert.attributes = params.require(:alert).permit!
    @alert.set_nextrun_at unless params[:reorder_to_position]

    respond_to do |format|
      if @alert.save
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to( :action => 'index' ) }
        format.api { render_api_ok }
      else
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@alert) }
      end
    end
  end

  # DELETE /alerts/:id
  def destroy
    if @alert.deletable? && @alert.editable_by?(User.current)
      @alert.reports.destroy_all
      @alert.archived_reports.destroy_all
      @alert.destroy
      flash[:notice] = l(:notice_successful_delete)
    end

    respond_to do |format|
      format.html { redirect_back_or_default( :action => 'index' ) }
    end
  end

  def context_changed
    if params[:alert][:context_id].blank?
      render :partial => 'empty/empty'
    else
      @rules = AlertRule.where(:context_id => params[:alert][:context_id]).all
      @rule_selected = nil
      @alert.rule = nil

      render :partial => 'context_rules_list_form'
    end
  end

  def rule_changed
    respond_to do |format|
      format.js
    end
    # if @alert.rule.nil?
    #   render :partial => 'empty/empty'
    # else
    #   render :partial => @alert.rule.get_settings_form
    # end
  end

  def custom_action
    @settings = params
    render :partial => @alert.rule.get_settings_form
  end

  def report
    @alert.generate_user_reports(User.current)

    respond_to do |format|
      format.html { redirect_to( :controller => 'alert_reports', :action => 'index', :alert_id => @alert ) }
    end
  end

  private

  def create_alert
    @alert = Alert.new(params[:alert] && params[:alert].permit!)
  end

  def find_alert
    @alert = Alert.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_and_fill_alert
    if params[:id].blank?
      @alert = Alert.new
    else
      @alert = Alert.find(params[:id])
    end

    @alert.attributes = params.require(:alert).permit!
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def set_class_variables
    @types = AlertType.all
    @contexts = AlertContext.all.select(&:visible?)

    if (@alert.new_record?)
      @rules = AlertRule.where(:context_id => params[:alert][:context_id]).all unless params[:alert].nil?
    else
      @rules = AlertRule.where(:context_id => @alert.rule.context.id).all
    end

    @rules ||= []

    @type_selected = @alert.type.id unless @alert.type.nil?
    @context_selected = @alert.context_id.to_i if !@alert.context_id.nil? && @alert.context_id.to_i > 0
    @rule_selected = @alert.rule.id unless @alert.rule.nil?
  end

  def set_settings
    @settings = {}

    if params[:issue]
      @issue = Issue.find(params[:issue])
      @settings[:issue_ids] = @issue.id.to_s
      @settings[:project_id] = @issue.project.id.to_s
    end
  end

  def check_permission_manage_alerts_for_all
    unless @alert.editable_by?(User.current)
      deny_access
    end
  end

  def check_permission_generate_report
    unless @alert.can_generate_report?(User.current)
      deny_access
    end
  end

end
