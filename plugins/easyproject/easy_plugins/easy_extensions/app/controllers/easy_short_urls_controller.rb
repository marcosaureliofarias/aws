class EasyShortUrlsController < ApplicationController

  before_action :find_easy_short_url_from_key, :only => [:shortcut]
  before_action :find_easy_short_url, :only => [:show, :edit, :update, :destroy]
  before_action :find_optional_entity, :only => [:index, :new, :create]

  skip_before_action :check_if_login_required, :only => [:shortcut]

  def index
    @easy_short_urls = EasyShortUrl.order(:valid_to => :desc)
    @easy_short_urls = @easy_short_urls.where(:entity_type => @entity.class.name, :entity_id => @entity.id) if @entity

    if @easy_short_urls.empty?
      redirect_to new_easy_short_url_path(:entity_type => params[:entity_type], :entity_id => params[:entity_id], :easy_short_url => { :source_url => params[:source_url] })
      return
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    respond_to do |format|
      format.html
      format.qr {
        @easy_qr = EasyQr.generate_qr(easy_shortcut_url(@easy_short_url.shortcut))
        if request.xhr?
          render :template => 'easy_qr/show', :formats => [:js], :locals => { :modal => true }
        else
          render :template => 'easy_qr/show', :formats => [:html], :content_type => 'text/html'
        end
      }
      format.js { render :action => 'show' }
    end
  end

  def new
    @easy_short_url                 = EasyShortUrl.new
    @easy_short_url.entity          = @entity
    @easy_short_url.safe_attributes = params[:easy_short_url]

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @easy_short_url                 = EasyShortUrl.new
    @easy_short_url.entity          = @entity
    @easy_short_url.safe_attributes = params[:easy_short_url]

    if @easy_short_url.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default easy_short_url_path(@easy_short_url)
        }
        format.js { show }
      end
      return
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.js { render :action => 'new' }
      end
    end
  end

  def edit
    @easy_short_url.safe_attributes = params[:easy_short_url]

    respond_to do |format|
      format.html
    end
  end

  def update
    @easy_short_url.safe_attributes = params[:easy_short_url]

    if @easy_short_url.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default easy_short_url_path(@easy_short_url)
        }
      end
      return
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
      end
    end
  end

  def destroy
    @easy_short_url.destroy
    flash[:notice] = l(:notice_successful_delete)

    respond_to do |format|
      format.html { redirect_back_or_default easy_short_urls_path }
    end
  end

  # Keep 2x `redirect_to` because of double render-or-redirect
  def shortcut
    @easy_short_url.add_access(User.current, current_user_ip)

    if @easy_short_url.allow_external?
      entity = @easy_short_url.entity

      case entity
      when Attachment
        send_attachment(entity)
      else
        redirect_to @easy_short_url.source_url
      end
    else
      redirect_to @easy_short_url.source_url
    end
  end

  def actions
    respond_to do |format|
      format.html
    end
  end

  private

  def send_attachment(attachment)
    if attachment.readable?
      send_file(attachment.diskfile, :filename => filename_for_content_disposition(attachment.filename),
                :type                          => detect_content_type(attachment),
                :disposition                   => (attachment.image? ? 'inline' : 'attachment'))
    else
      logger.error "Cannot send attachment, #{attachment.diskfile} does not exist or is unreadable."
      render_404
    end
  end

  def find_easy_short_url
    @easy_short_url = EasyShortUrl.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_easy_short_url_from_key
    @easy_short_url = EasyShortUrl.where(:shortcut => params[:shortcut]).first
    render_404 if @easy_short_url.nil? || !@easy_short_url.still_valid?
  end

  def find_optional_entity
    entity_klass = begin
      ; params[:entity_type].constantize;
    rescue;
      nil;
    end if params[:entity_type]
    return if entity_klass.nil?

    if entity_klass.respond_to?(:visible)
      @entity = entity_klass.visible.find(params[:entity_id]) if params[:entity_id]
    else
      @entity = entity_klass.find(params[:entity_id]) if params[:entity_id]
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
