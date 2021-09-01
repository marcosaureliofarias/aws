class EasyBroadcastsController < ApplicationController
  layout 'admin'

  menu_item :easy_broadcasts

  accept_api_auth :index, :show, :create, :update, :destroy, :active_broadcasts, :mark_as_read

  before_action :authorize_global, except: [:mark_as_read, :active_broadcasts]
  before_action :find_easy_broadcast, only: [:show, :edit, :update, :mark_as_read]
  before_action :find_easy_broadcasts, only: [:context_menu, :bulk_edit, :bulk_update, :destroy]

  helper :easy_broadcasts
  helper :context_menus
  helper :issues
  include_query_helpers

  def index
    index_for_easy_query(EasyBroadcastQuery)
  end

  def show
    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    user_time                       = User.current.user_time_in_zone(Time.now)
    @easy_broadcast                 = EasyBroadcast.new(start_at: user_time, end_at: user_time)
    @easy_broadcast.safe_attributes = params[:easy_broadcast]

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @easy_broadcast                 = EasyBroadcast.new
    @easy_broadcast.safe_attributes = params[:easy_broadcast]
    @easy_broadcast.author          = User.current

    set_interval_params

    if @easy_broadcast.save
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default easy_broadcasts_path
        }
        format.api { render_api_ok }
        format.js
      end
    else
      user_time                = User.current.user_time_in_zone(Time.now)
      @easy_broadcast.start_at ||= user_time
      @easy_broadcast.end_at   ||= user_time
      respond_to do |format|
        format.html { render action: 'new' }
        format.api { render_validation_errors(@easy_broadcast) }
        format.js { render action: 'new' }
      end
    end
  end

  def edit
    @easy_broadcast.safe_attributes = params[:easy_broadcast]

    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    @easy_broadcast.safe_attributes = params[:easy_broadcast]

    set_interval_params

    if @easy_broadcast.save
      @easy_broadcast.user_read_records.destroy_all
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default easy_broadcasts_path
        }
        format.api { render_api_ok }
        format.js { render template: 'common/close_modal' }
      end
    else
      respond_to do |format|
        format.html { render action: 'edit' }
        format.api { render_validation_errors(@easy_broadcast) }
        format.js { render action: 'edit' }
      end
    end
  end

  def destroy
    @easy_broadcasts.each do |easy_broadcast|
      easy_broadcast.destroy
    end

    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_delete)
        redirect_back_or_default easy_broadcasts_path
      }
      format.api { render_api_ok }
    end
  end

  def context_menu
    if (@easy_broadcasts.size == 1)
      @easy_broadcast = @easy_broadcasts.first
    end
    @easy_broadcast_ids = @easy_broadcasts.map(&:id).sort

    can_edit   = @easy_broadcasts.detect { |c| !c.editable? }.nil?
    can_delete = @easy_broadcasts.detect { |c| !c.deletable? }.nil?
    @can       = { :edit => can_edit, :delete => can_delete }
    @back      = back_url

    @safe_attributes = @easy_broadcasts.map(&:safe_attribute_names).reduce(:&)

    render :layout => false
  end

  def mark_as_read
    @easy_broadcast.mark_as_read User.current

    respond_to do |format|
      format.api { render_api_ok }
    end
  end

  def active_broadcasts
    # This should be part of EasyBackgroundService now
    @easy_broadcasts = EasyBroadcast.active_for_current_user

    respond_to do |format|
      format.api
    end
  end

  private

  def set_interval_params
    @easy_broadcast.start_at = EasyUtils::DateUtils.build_datetime_from_params("#{params[:start_at_date]} #{params[:start_at_time]}") if params[:start_at_date] && params[:start_at_time]
    @easy_broadcast.end_at   = EasyUtils::DateUtils.build_datetime_from_params("#{params[:end_at_date]} #{params[:end_at_time]}") if params[:end_at_date] && params[:end_at_time]
  end

  def find_easy_broadcast
    @easy_broadcast = EasyBroadcast.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_easy_broadcasts
    @easy_broadcasts = EasyBroadcast.visible.where(id: (params[:id] || params[:ids])).to_a
    raise ActiveRecord::RecordNotFound if @easy_broadcasts.empty?
    raise Unauthorized unless @easy_broadcasts.all?(&:visible?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end