class EasyHelpdeskMailTemplatesController < ApplicationController
  layout 'admin'

  before_action :authorize_global
  before_action :find_easy_helpdesk_mail_template, :only => [:show, :edit, :update, :destroy]

  helper :sort
  include SortHelper
  helper :easy_helpdesk_mail_templates
  include EasyHelpdeskMailTemplatesHelper

  def index
    scope = EasyHelpdeskMailTemplate.includes([:issue_status, :mailboxes]).order(:name)
    @easy_helpdesk_mail_templates_pages, @easy_helpdesk_mail_templates = paginate scope

    respond_to do |format|
      format.html
    end
  end

  def show
    respond_to do |format|
      # format.html
    end
  end

  def new
    @easy_helpdesk_mail_template = EasyHelpdeskMailTemplate.new
    @easy_helpdesk_mail_template.safe_attributes = params[:easy_helpdesk_mail_template]

    respond_to do |format|
      format.html
    end
  end

  def create
    @easy_helpdesk_mail_template = EasyHelpdeskMailTemplate.new
    @easy_helpdesk_mail_template.safe_attributes = params[:easy_helpdesk_mail_template]

    if @easy_helpdesk_mail_template.save
      respond_to do |format|
        format.html  {
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default(:action => 'index')
        }
      end
    else
      respond_to do |format|
        format.html  { render :action => 'new' }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    @easy_helpdesk_mail_template.safe_attributes = params[:easy_helpdesk_mail_template]

    if @easy_helpdesk_mail_template.save
      respond_to do |format|
        format.html  {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default(:action => 'index')
        }
      end
    else
      respond_to do |format|
        format.html  { render :action => 'edit' }
      end
    end
  end

  def destroy
    @easy_helpdesk_mail_template.destroy

    redirect_back_or_default(:action => 'index')
  end

  private

  def find_easy_helpdesk_mail_template
    @easy_helpdesk_mail_template = EasyHelpdeskMailTemplate.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
