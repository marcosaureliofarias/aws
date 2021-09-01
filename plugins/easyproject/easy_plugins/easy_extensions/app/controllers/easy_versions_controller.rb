class EasyVersionsController < ApplicationController

  before_action :authorize_global, only: [:index, :new, :create]

  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :versions
  include VersionsHelper
  helper :projects
  include ProjectsHelper

  accept_api_auth :index

  EasyExtensions::EasyPageHandler.register_for(self, {
      page_name:   'milestones-overview',
      path:        proc { overview_easy_versions_path(t: params[:t]) },
      show_action: :overview,
      edit_action: :overview_layout
  })

  def index
    index_for_easy_query EasyVersionQuery
  end

  def new
    @version = Version.new
    @project = Project.find(params[:project_id]) if params[:project_id]
    if @project
      redirect_to(new_project_version_path(@project))
    else
      @projects = Project.visible.non_templates.sorted unless request.xhr?
      render :layout => !request.xhr?
    end
  end

  def create
    @version   = Version.new
    attributes = params[:version].dup
    attributes.delete('sharing') unless attributes.nil? || @version.allowed_sharings.include?(attributes['sharing'])
    @version.safe_attributes = attributes

    if @version.save
      flash[:notice] = l(:notice_successful_create)
      redirect_back_or_default :action => 'index'
    else
      render :action => 'new'
    end
  end

end
