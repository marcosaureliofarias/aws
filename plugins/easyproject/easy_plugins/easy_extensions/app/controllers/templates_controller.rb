class TemplatesController < ApplicationController
  layout 'admin'

  before_action :render_403, only: [:show_create_project, :show_copy_project, :make_project_from_template, :copy_project_from_template], if: -> { !EasyLicenseManager.has_license_limit?(:active_project_limit) }
  before_action :authorize_global, :only => [:destroy, :bulk_destroy]
  before_action :find_source_project, :except => [:index, :bulk_destroy, :render_shifted_time_duration]
  before_action :get_and_initialize_projects, :only => [:show_create_project, :show_copy_project]
  before_action :build_template_params, :only => [:show_create_project]
  before_action :authorize_create_project_from_template, :only => [:make_project_from_template, :show_create_project, :copy_project_from_template, :index]
  before_action :authorize_create_project_template, :only => [:add]

  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :projects
  include ProjectsHelper
  helper :context_menus
  include ContextMenusHelper

  accept_api_auth :index, :restore, :add, :make_project_from_template, :copy_project_from_template, :destroy

  # Lists visible projects
  def index
    retrieve_query(EasyProjectTemplateQuery)
    sort_init(@query.sort_criteria_init)
    sort_update(@query.sortable_columns)

    prepare_easy_query_render

    if request.xhr? && !@entities
      render_404
      return false
    end

    respond_to do |format|
      format.html {
        render_easy_query
      }
      format.api
    end
  end

  # Restores template to the original project
  def restore
    @source_project.to_projects!

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_restore_template)
        redirect_to :controller => 'templates', :action => 'index'
      }
      format.api { render_api_ok }
    end
  end

  # Creates a template from the project
  def add
    templates = {}

    Mailer.with_deliveries(false) do
      templates = @source_project.create_project_templates(:copying_action => :creating_template, :copy_author => true)
    end

    respond_to do |format|
      if templates[:unsaved].any?
        err_msg = (l(:error_can_not_create_project_template, :projectname => ERB::Util.html_escape(templates[:unsaved].first.name)) + '<br>' + templates[:unsaved].first.errors.full_messages.join('<br>')).html_safe
        format.html {
          flash[:error] = err_msg
          redirect_to :controller => 'projects', :action => 'settings', :id => @source_project
        }
        format.api { render_api_error(err_msg) }
      else
        format.html {
          flash[:notice] = l(:notice_successful_create_template)
          redirect_to :controller => 'templates', :action => 'index'
        }
        format.api { render_api_ok }
      end
    end
  end

  # Shows form to create project from template
  def show_create_project
    @new_project ||= Project.new(is_public: true, is_from_template: true)

    respond_to do |format|
      format.html { render template: 'templates/create' }
    end
  end

  # Shows form to create project from template
  def show_copy_project
    respond_to do |format|
      format.html { render template: 'templates/copy' }
    end
  end

  # Creates a project from the template
  def make_project_from_template
    @new_project, saved_projects, unsaved_projects = nil
    params[:template]                              ||= {}
    if params[:template][:parent_id].blank?
      params[:template] = params[:template].except(:inherit_easy_invoicing_settings, :inherit_time_entry_activities, :inherit_easy_money_settings)
    end

    params_template    = params[:template].respond_to?(:to_unsafe_h) ? params[:template].to_unsafe_h.with_indifferent_access : {}
    project_attributes = params_template[:project]
    # Set default project templates - for easy api.
    project_attributes ||= @source_project.self_and_descendants.where("#{Project.table_name}.status <> ?", Project::STATUS_ARCHIVED).select([:id, :name]).collect { |p| { 'id' => p.id.to_s, 'name' => p.name } }
    errors             = []

    options = project_from_template_options

    unless params[:template][:change_issues_author].blank?
      options[:copy_author] = false
      options[:issues]      = { author_id: params[:template][:change_issues_author] }
    end

    Mailer.with_deliveries(params[:notifications] == '1') do
      Project.transaction do
        @new_project, saved_projects, unsaved_projects = @source_project.project_with_subprojects_from_template(params[:template][:parent_id], project_attributes, options)
        unless unsaved_projects.empty?
          errors = unsaved_projects.compact.map { |p| p.errors.full_messages.join(', ') }
          raise ActiveRecord::Rollback
        end
      end
    end if errors.empty?

    if errors.empty? && unsaved_projects.empty?
      shifted_projects = []
      if params.dig(:template, :dates_settings) == 'update_dates' && (new_start_date = params.dig(:template, :start_date)&.to_date).present?
        saved_projects.each do |project|
          next unless project.start_date

          day_shift = (new_start_date - project.start_date).to_i
          project.update_project_entities_dates(day_shift)

          shifted_projects << project
        end if new_start_date.is_a?(Date)
      end

      if params.dig(:template, :dates_settings) == 'match_starting_dates'
        saved_projects.each do |project|
          project.match_starting_dates
          shifted_projects << project unless shifted_projects.include?(project)
        end
      end

      if params[:template] && params[:template][:assign_entity] &&
          (entity_class = begin
            ; params[:template][:assign_entity][:type].constantize rescue nil;
          end) &&
          (entity = entity_class.find_by(id: params[:template][:assign_entity][:id]))
        if params[:template][:assign_entity][:type] == 'EasyContact'
          unless @new_project.easy_contact_entity_assignments.where(entity_type: 'Project', easy_contact_id: entity.id).exists?
            EasyContactEntityAssignment.create(entity: @new_project, easy_contact_id: entity.id)
          end
        else
          EasyEntityAssignment.create(entity_to: @new_project, entity_from: entity)
        end
      end

      shifted_projects.each do |p|
        Redmine::Hook.call_hook(:model_project_after_day_shifting, { :project => p })
      end

      copy_time_entry_settings(params[:template], saved_projects)
      Redmine::Hook.call_hook(:controller_templates_create_project_from_template, { :source_project => @source_project, :params => params, :saved_projects => saved_projects, :unsaved_projects => unsaved_projects })
    end

    respond_to do |format|
      if errors.empty? && unsaved_projects.empty?
        flash[:notice] = l(:notice_successful_create_project_from_template)
        format.html do
          if User.current.allowed_to?({ :controller => 'projects', :action => 'settings' }, @new_project)
            redirect_to(settings_project_path(@new_project))
          else
            redirect_to(project_path(@new_project))
          end
        end
        format.api {
          @project = @new_project
          render :template => 'projects/show', :status => :created, :location => project_path(@project)
        }
      else
        get_and_initialize_projects
        build_template_params
        build_new_project if @new_project.nil?
        err_msg           = if errors.empty?
                              l(:notice_failed_create_project_from_template, :errors => l(:error_required_fields_missing))
                            else
                              errors.map { |err| l(:notice_failed_create_project_from_template, :errors => err) }.join('<br>').html_safe
                            end
        flash.now[:error] = err_msg
        format.html { render 'create' }
        format.api { render_api_error(err_msg) }
      end
    end
  end

  def copy_project_from_template
    if params[:template]
      target_root_project = Project.find_by(:id => params[:template][:target_root_project_id]) if params[:template][:target_root_project_id]
      target_version_ids  = []
      target_issue_ids    = []
      source_start_date   = nil
      new_start_date      = nil

      if target_root_project
        Mailer.with_deliveries(false) do
          target_root_project.delete_easy_page_modules
          target_version_ids = target_root_project.versions.pluck(:id)
          target_issue_ids   = target_root_project.issues.pluck(:id)
          source_start_date  = @source_project.start_date
          target_root_project.copy(@source_project, {})
        end

        saved_projects = [target_root_project]
      else
        flash[:error] = l(:error_project_not_selected)

        respond_to do |format|
          format.html {
            redirect_to(:controller => 'templates', :action => 'show_copy_project', :id => @source_project)
          }
          format.api {
            err_msg = l(:notice_failed_create_project_from_template, :errors => l(:error_required_fields_missing))
            render_api_error(err_msg)
          }
        end
        return
      end

      if !target_root_project.nil? && target_root_project.valid?
        source_issues   = Issue.where(:project_id => saved_projects).where.not(:id => target_issue_ids)
        source_versions = Version.where(:project_id => saved_projects).where.not(:id => target_version_ids)
        if params[:template][:start_date]
          new_start_date = begin
            ; params[:template][:start_date].to_date;
          rescue;
            Date.today;
          end
        end

        if new_start_date && source_start_date
          if params.dig(:template, :dates_settings) == 'update_dates'
            day_shift = (new_start_date - source_start_date).to_i
            Project.update_project_entity_dates(source_issues, ['created_on', 'start_date', 'due_date', 'updated_on'], day_shift)
            Project.update_project_entity_dates(source_versions, ['created_on', 'effective_date', 'updated_on'], day_shift)
            Project.update_project_entity_dates(saved_projects, ['created_on', 'updated_on', 'easy_start_date', 'easy_due_date'], day_shift)
          end
          if params.dig(:template, :dates_settings) == 'match_starting_dates'
            source_issues.each do |issue|
              issue.update_columns(start_date: source_start_date, due_date: source_start_date + issue.duration.to_i.days)
            end
          end
        end

        if !params[:template][:change_issues_author].blank?
          source_issues.update_all(:author_id => params[:template][:change_issues_author])
        end

        saved_projects.each do |p|
          Redmine::Hook.call_hook(:model_project_after_day_shifting, { :project => p })
        end
      end
    end
    respond_to do |format|

      if target_root_project.nil? || !target_root_project.valid?
        if target_root_project.nil?
          err_msg = l(:notice_failed_create_project_from_template, :errors => l(:error_required_fields_missing))
        else
          err_msg = l(:notice_failed_create_project_from_template, :errors => target_root_project.errors.full_messages.join(','))
        end
        flash[:error] = err_msg
        format.html { redirect_to(:controller => 'templates', :action => 'show_copy_project', :id => @source_project) }
        format.api { render_api_error(err_msg) }
      else
        flash[:notice] = l(:notice_successful_create_project_from_template)
        format.html { redirect_to(:controller => 'projects', :action => 'settings', :id => target_root_project) }
        format.api {
          @project = @new_project
          render :template => 'projects/show', :status => :created, :location => project_path(@project)
        }
      end

    end
  end

  def destroy
    @source_project.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_to :controller => 'templates', :action => 'index'
  rescue
    flash[:error] = l(:error_can_not_delete_project_template)
    redirect_to :controller => 'templates', :action => 'index'
  end

  def bulk_destroy
    Project.where(:id => params[:ids]).destroy_all
    flash[:notice] = l(:notice_successful_delete)
    redirect_to :controller => 'templates', :action => 'index'
  rescue
    flash[:error] = l(:error_can_not_delete_project_template)
    redirect_to :controller => 'templates', :action => 'index'
  end

  def render_shifted_time_duration
    new_start_date = params[:new_start_date].to_date rescue nil
    start_date = params[:start_date].to_date rescue nil
    if new_start_date && start_date
      duration_text = view_context.distance_of_time_in_words(new_start_date, start_date)
      notice = l(:text_start_date_will_be_shifted_by, duration: duration_text)
    end
    render json: { text: notice }
  end

  private

  def project_from_template_options
    { :copying_action => :creating_project, :copy_author => true, :easy_start_date => params[:template][:start_date] }
  end

  def find_source_project
    @source_project                  = Project.find(params[:id])
    @source_project.is_from_template = true
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def get_and_initialize_projects
    @projects = @source_project.reload.self_and_descendants.where("#{Project.table_name}.status <> ?", Project::STATUS_ARCHIVED).to_a
    @projects.each_with_index { |p, i| p.reinitialize_values(i) }
  end

  def build_template_params
    if params[:template].present?
      @template_params = params[:template]
      if @template_params[:project]
        @project_params     = Array.wrap(@template_params[:project]).first
        @project_identifier = @project_params[:identifier]
      end
    else
      @template_params = { default_settings: true, dates_settings: 'update_dates' }
    end
    @project_identifier ||= Project.next_identifier if Setting.sequential_project_identifiers?
  end

  def build_new_project
    if @projects.present? && @template_params.present? && @project_params.present?
      @source_project.parent_id        = @template_params[:parent_id]
      @source_project.is_from_template = true
      @new_project                     = @projects.first
      @new_project.custom_field_values = @project_params[:custom_field_values] || {}
      @new_project.name                = @project_params[:name]
      @new_project.is_from_template    = true
    end
  end

  def authorize_create_project_from_template
    render_403 unless Project.allowed_to_create_project_from_template?
  end

  def authorize_create_project_template
    render_403 unless User.current.allowed_to?(:create_project_template, @source_project)
  end

end
