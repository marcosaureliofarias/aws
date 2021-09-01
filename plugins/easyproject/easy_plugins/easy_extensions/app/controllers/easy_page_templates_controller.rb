class EasyPageTemplatesController < ApplicationController

  before_action { |c| c.require_admin_or_lesser_admin(:easy_pages_administration) }
  before_action :find_project
  before_action :find_page, :except => [:move, :show_page_template, :edit_page_template]
  before_action :find_template, :only => [:show, :edit, :update, :destroy, :move, :show_page_template, :edit_page_template]
  before_action :find_page_from_template, :only => [:move, :show_page_template, :edit_page_template]

  # GET /easy_page_templates/page/:page_id
  def index
    @page_templates = @page.templates
    respond_to do |format|
      format.html { render :layout => 'admin' }
    end
  end

  # GET /easy_page_templates/:id
  # GET /easy_page_templates/:id/show
  def show

  end

  # GET /easy_page_templates/page/:page_id/new
  def new
    @page_template                 = EasyPageTemplate.new
    @page_template.safe_attributes = {
        'easy_pages_id'         => params[:page_id],
        'copy_from_type'        => params[:copy_from_type],
        'copy_from_user_id'     => params[:copy_from_user_id],
        'copy_from_entity_id'   => params[:copy_from_entity_id],
        'copy_from_template_id' => params[:copy_from_template_id],
        'copy_from_tab_id'      => params[:copy_from_tab_id]
    }
  end

  # POST /easy_page_templates
  def create
    @page_template                 = EasyPageTemplate.new
    @page_template.safe_attributes = params[:easy_page_template]

    respond_to do |format|
      if @page_template.save
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to(:action => 'index', :page_id => @page.id) }
      else
        format.html { render :action => 'new', :page_id => @page.id }
      end
    end

  end

  # GET /easy_page_templates/page/:page_id/:id/edit
  def edit

  end

  # PUT /easy_page_templates/:id
  def update
    respond_to do |format|
      @page_template.safe_attributes = params[:easy_page_template]
      if @page_template.save
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to(:action => 'index', :page_id => @page.id) }
        format.api { render_api_ok }
      else
        format.html { render :action => "edit", :page_id => @page.id }
        format.api { render_validation_errors(@page_template) }
      end
    end
  end

  # DELETE /easy_page_templates/:id
  def destroy
    @page_template.destroy

    respond_to do |format|
      flash[:notice] = l(:notice_successful_delete)
      format.html { redirect_to(:action => 'index', :page_id => @page.id) }
    end
  end

  # GET /easy_page_templates/:id/move
  # def move
  #   @page_template.update_attributes(params[:easy_page_template])
  #   redirect_to( :action => 'index', :page_id => @page.id )
  # end

  def show_page_template
    render_action_as_easy_page_template(@page_template, User.current, nil, easy_page_templates_show_page_template_path(id: @page_template.id, t: params[:t]), false, page_editable: User.current.allowed_to_globally?(:manage_my_page))
  end

  def edit_page_template
    render_action_as_easy_page_template(@page_template, User.current, nil, easy_page_templates_show_page_template_path(id: @page_template.id, t: params[:t]), true, page_editable: User.current.allowed_to_globally?(:manage_my_page))
  end

  private

  def find_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_template
    #@template is reserved variable!
    @page_template = EasyPageTemplate.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_page
    @page = params[:page_id].nil? ? EasyPage.find((params[:easy_page_template] ? params[:easy_page_template][:easy_pages_id] : nil)) : EasyPage.find(params[:page_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_page_from_template
    @page = @page_template.page_definition unless @page_template.nil?
  end

end
