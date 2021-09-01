class EasyPdfThemesController < ApplicationController

  layout 'admin'

  before_action :require_admin
  before_action :find_pdf_theme, :only => [:edit, :update, :destroy]

  def index
    @pdf_themes = EasyPdfTheme.all
  end

  def new
    @pdf_theme = EasyPdfTheme.new
  end

  def create
    @pdf_theme                 = EasyPdfTheme.new
    @pdf_theme.safe_attributes = params[:easy_pdf_theme]
    if @pdf_theme.save && save_logo
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    @pdf_theme.safe_attributes = params[:easy_pdf_theme]
    if @pdf_theme.save && save_logo
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end

  def destroy
    @pdf_theme.destroy
    redirect_to :action => 'index'
  end

  private

  def find_pdf_theme
    @pdf_theme = EasyPdfTheme.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def save_logo
    return true unless logo = params[:easy_pdf_theme][:logo]
    begin
      EasyExtensions::ImageProcessing.resize_image_to_fit(logo.path, 400, 100, { :format => 'JPG' })
    rescue EasyExtensions::ImageProcessing::AdapterProcessException
      flash[:error] = l(:avatar_invalid_file)
      return false
    rescue EasyExtensions::ImageProcessing::MissingAdapterException
      flash[:warning] = l(:warning_without_imagemagick) unless EasySetting.value('hide_imagemagick_warning')
    end
    @pdf_theme.save_attachments({ 'first' => { 'file' => logo, 'description' => @pdf_theme.name } })
    @pdf_theme.attach_saved_attachments
    true
  end

end
