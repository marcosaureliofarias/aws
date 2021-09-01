class EasyChecklistsController < ApplicationController

  accept_api_auth :show, :create, :update, :destroy

  before_action :new_easy_checklist, :only => [:create]
  before_action :find_easy_checklist, :except => [:index, :new, :create, :add_to_entity, :settings, :append_template]
  before_action :find_entity, :only => [:add_to_entity]
  before_action :find_easy_checklist_template, :only => [:add_to_entity, :append_template]

  before_action :set_checklist_attributes, :only => [:create, :update]
  before_action :set_project_for_authorization, :only => [:create, :update]
  before_action :set_visible_projects, :only => [:new, :edit]
  # only for templates
  before_action :authorize_global, :only => [:new, :index, :create, :edit, :update], :if => Proc.new { @project.blank? }
  before_action :authorize, :only => [:new, :create, :edit, :update], :if => Proc.new { @project.present? }
  before_action :authorize_easy_checklist, :only => [:edit, :update]
  before_action :find_optional_project

  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :easy_setting
  include EasySettingHelper

  def index
    index_for_easy_query EasyChecklistQuery, [['name', 'asc']] if Redmine::Plugin.installed?(:easy_extensions)
  end

  def new
    new_easy_checklist
    @easy_checklist = EasyChecklistTemplate.new(:prepare_items => true)
    @easy_checklist.projects << @project if @project
  end

  def create
    if @easy_checklist.save
      respond_to do |format|
        format.js
        format.html { redirect_back_or_default easy_checklists_path }
        format.api { render action: :show }
      end
    else
      respond_to do |format|
        format.js
        format.html { render :action => 'new' }
        format.json { render_api_errors(@easy_checklist.errors.full_messages) }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { redirect_to edit_easy_checklist_path(@easy_checklist) }
      format.api
    end
  end

  def edit
  end

  def update
    @easy_checklist.settings ||= {}
    @easy_checklist.settings['display_mode'] = params[:display_mode] if params[:display_mode]

    if @easy_checklist.save
      respond_to do |format|
        format.js
        format.html { redirect_to easy_checklists_path }
        format.api { render action: :show }
      end
    else
      respond_to do |format|
        format.js
        format.html { render :action => 'edit' }
        format.api { render_api_errors(@easy_checklist.errors.full_messages) }
      end
    end
  end

  def update_display_mode
    @easy_checklist.settings ||= {}
    @easy_checklist.settings['display_mode'] = params[:display_mode] if params[:display_mode]

    @easy_checklist.save
    respond_to do |format|
      format.js
    end
  end

  def destroy
    return render_403 unless @easy_checklist.can_edit?

    @easy_checklist.destroy

    respond_to do |format|
      format.js
      format.html {
        redirect_back_or_default easy_checklists_path
      }
      format.api { render_api_head :no_content }
    end
  end

  def add_to_entity
    if (@easy_checklist_template.add_to_entity(@entity))
      @success = true
    end

    respond_to do |format|
      format.js
    end
  end

  def settings
    save_easy_settings if request.put?

    respond_to do |format|
      format.html
    end
  end

  def append_template
    @easy_checklist = @easy_checklist_template
    klass = (begin; params[:entity_type].to_s.constantize; rescue; nil; end)
    @entity = klass.new
    @easy_checklist.entity = @entity

    respond_to do |format|
      format.js
    end
  end

  private

  def authorize_easy_checklist
    return render_403 unless @easy_checklist.can_edit?
  end

  def new_easy_checklist
    klass = (begin; params[:entity_type].to_s.constantize; rescue; nil; end)
    klass = EasyChecklist if klass.nil?
    @easy_checklist = klass.new
    @easy_checklist_item = EasyChecklistItem.new
  end

  def find_easy_checklist
    @easy_checklist = EasyChecklist.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_easy_checklist_template
    @easy_checklist_template = EasyChecklistTemplate.find(params[:easy_checklist_template_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def set_checklist_attributes
    @easy_checklist.safe_attributes = params[:easy_checklist]
    @easy_checklist.author = User.current

    @easy_checklist.easy_checklist_items.each do |easy_checklist_item|
      easy_checklist_item.author = User.current
    end
  end

  def find_entity
    klass = (begin; params[:entity_type].to_s.constantize; rescue; nil; end)
    @entity = klass.find(params[:entity_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def set_project_for_authorization
    @project = @easy_checklist.entity.try(:project)
  end

  def set_visible_projects
    @projects = Project.allowed_to(:manage_easy_checklist_templates)
  end
end
