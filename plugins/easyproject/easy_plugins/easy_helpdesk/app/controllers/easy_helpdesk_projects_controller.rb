class EasyHelpdeskProjectsController < ApplicationController
  layout 'admin'

  before_action :authorize_global
  before_action :find_easy_helpdesk_project, :only => [:show, :edit, :update]
  before_action :find_easy_helpdesk_projects, :only => [:bulk_edit, :bulk_update, :destroy]
  before_action :build_auto_closer_relation, :only => [:edit]
  before_render :set_aggregated_hours_fields, :only => [:new, :edit]
  before_action :issue_statuses, only: [:edit, :update, :new, :create]

  helper :easy_query
  include EasyQueryHelper
  helper :easy_helpdesk_projects
  include EasyHelpdeskProjectsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :sort
  include SortHelper
  helper :projects
  include ProjectsHelper
  helper :easy_setting
  include EasySettingHelper

  accept_api_auth :find_by_email

  def index
    retrieve_query(EasyHelpdeskProjectQuery)
    sort_init(@query.sort_criteria.empty? ? [['project', 'asc']] : @query.sort_criteria)
    sort_update(@query.sortable_columns)

    @ehp = prepare_easy_query_render

    if request.xhr? && !@entities
      render_404
      return false
    end

    respond_to do |format|
      format.html { render_easy_query_html }
      format.csv  { send_data(export_to_csv(@ehp, @query), filename: get_export_filename(:csv, @query, l(:heading_easy_helpdesk_projects_index)))}
      format.pdf  { send_file_headers! :type => 'application/pdf', :filename => get_export_filename(:pdf, @query, l(:heading_easy_helpdesk_projects_index)) }
      format.xlsx { send_data(export_to_xlsx(@ehp, @query, :default_title => l(:heading_easy_helpdesk_projects_index)), :filename => get_export_filename(:xlsx, @query, l(:heading_easy_helpdesk_projects_index)))}
    end
  end

  def show
    redirect_to(:action => 'edit', :id => @easy_helpdesk_project)
  end

  def new
    @easy_helpdesk_project = EasyHelpdeskProject.new
    @easy_helpdesk_project.safe_attributes = params[:easy_helpdesk_project]

    @easy_helpdesk_project.easy_helpdesk_project_matching.build if @easy_helpdesk_project.easy_helpdesk_project_matching.blank?
    build_auto_closer_relation

    respond_to do |format|
      format.html
      format.js { render :template => 'easy_helpdesk_projects/update_form'}
    end
  end

  def create
    @easy_helpdesk_project = EasyHelpdeskProject.new
    @easy_helpdesk_project.safe_attributes = params[:easy_helpdesk_project]
    save_easy_settings(@easy_helpdesk_project.project_id) if @easy_helpdesk_project.project_id

    unless params[:enable_email_header]
      @easy_helpdesk_project.email_header = nil
    end
    unless params[:enable_email_footer]
      @easy_helpdesk_project.email_footer = nil
    end

    if @easy_helpdesk_project.save
      respond_to do |format|
        format.html  {
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default(:action => 'index')
        }
      end
    else
      respond_to do |format|
        format.html  { render :action => 'new' }
        format.js { render :template => 'easy_helpdesk_projects/update_form'}
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.js { render :template => 'easy_helpdesk_projects/update_form'}
    end
  end

  def update
    @easy_helpdesk_project.safe_attributes = params[:easy_helpdesk_project]
    save_easy_settings(@easy_helpdesk_project.project_id) if @easy_helpdesk_project.project_id

    unless params[:enable_email_header]
      @easy_helpdesk_project.email_header = nil
    end
    unless params[:enable_email_footer]
      @easy_helpdesk_project.email_footer = nil
    end

    if @easy_helpdesk_project.save
      respond_to do |format|
        format.html  {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default(:action => 'index')
        }
      end
    else
      respond_to do |format|
        format.html  { render :action => 'edit' }
        format.js { render :template => 'easy_helpdesk_projects/update_form'}
      end
    end
  end

  def destroy
    @easy_helpdesk_projects.each do |easy_helpdesk_projects|
      easy_helpdesk_projects.destroy
    end

    redirect_back_or_default(:action => 'index')
  end

  def bulk_edit

    render :layout => false if request.xhr?
  end

  def bulk_update
    attributes = parse_params_for_bulk_easy_helpdesk_project_attributes(params)

    saved_entities, unsaved_entities = [], []

    @easy_helpdesk_projects.each do |easy_helpdesk_project|
      easy_helpdesk_project.safe_attributes = attributes

      if easy_helpdesk_project.save
        saved_entities << easy_helpdesk_project
      else
        unsaved_entities << easy_helpdesk_project
      end
    end

    set_flash_from_bulk_easy_helpdesk_project_save(@easy_helpdesk_projects, unsaved_entities.collect(&:id))

    redirect_back_or_default({:controller => 'easy_helpdesk_projects', :action => 'index'})
  end

  def copy_sla
    @easy_helpdesk_project = EasyHelpdeskProject.new(project_id: params[:project_id])
    easy_helpdesk_project = EasyHelpdeskProject.find_by(project_id: params[:copy_settings_sla_from_project][:project_id]) if params[:copy_settings_sla_from_project]
    @easy_helpdesk_project_sla = (easy_helpdesk_project.present? ? easy_helpdesk_project.easy_helpdesk_project_sla.sorted : [])

    respond_to do |format|
      format.js
    end
  end

  def find_by_email
    @easy_helpdesk_project = EasyHelpdesk::ProjectFinder.by_email(params[:subject], params[:from], params[:to], params[:mailbox_username])

    respond_to do |format|
      format.api {
        unless @easy_helpdesk_project
          render_error message: "Project not found.", status: 404
        end
      }
    end
  end

  private

  def find_easy_helpdesk_project
    @easy_helpdesk_project = EasyHelpdeskProject.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_easy_helpdesk_projects
    @easy_helpdesk_projects = EasyHelpdeskProject.where(:id => (params[:id] || params[:ids])).preload(:project).to_a
    raise ActiveRecord::RecordNotFound if @easy_helpdesk_projects.empty?
    @projects = @easy_helpdesk_projects.collect(&:project).compact.uniq
    #@project = @projects.first if @projects.size == 1
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def parse_params_for_bulk_easy_helpdesk_project_attributes(params)
    attributes = (params[:easy_helpdesk_project] || {}).reject {|k,v| v.blank?}
    attributes.each_key {|k| attributes[k] = '' if attributes[k] == 'none'}
    if custom = attributes[:custom_field_values]
      custom.reject! {|k,v| v.blank?}
      custom.each_key do |k|
        if custom[k].is_a?(Array)
          custom[k] << '' if custom[k].delete('__none__')
        else
          custom[k] = '' if custom[k] == '__none__'
        end
      end
    end
    attributes
  end

  def set_flash_from_bulk_easy_helpdesk_project_save(easy_helpdesk_projects, unsaved_ids)
    if unsaved_ids.empty?
      flash[:notice] = l(:notice_successful_update) unless easy_helpdesk_projects.empty?
    else
      flash[:error] = l(:notice_failed_to_save_issues,
        :count => unsaved_ids.size,
        :total => easy_helpdesk_projects.size,
        :ids => '#' + unsaved_ids.join(', #'))
    end
  end

  def set_aggregated_hours_fields
    if @easy_helpdesk_project
      @easy_helpdesk_project.aggregated_hours_start_date ||= @easy_helpdesk_project.project.try(:start_date) || Date.today
      @easy_helpdesk_project.aggregated_hours_period ||= 'quarterly'
      @easy_helpdesk_project.aggregated_hours_remaining ||= @easy_helpdesk_project.monthly_hours
    end
  end

  def build_auto_closer_relation
    @easy_helpdesk_project.easy_helpdesk_auto_issue_closers.build if @easy_helpdesk_project && @easy_helpdesk_project.easy_helpdesk_auto_issue_closers.blank?
  end

  def issue_statuses
    @issue_statuses = IssueStatus.preload(:easy_helpdesk_mail_templates).sorted
  end
end
