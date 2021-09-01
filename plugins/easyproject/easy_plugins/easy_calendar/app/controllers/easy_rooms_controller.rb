class EasyRoomsController < ApplicationController

  layout 'admin'

  before_action :authorize_global, only: [:availability]
  before_action :require_admin, except: [:availability]
  before_action :find_easy_room
  before_action :require_easy_room, only: [:show, :edit, :update]

  def new
    @easy_room = EasyRoom.new
  end

  def create
    @easy_room = EasyRoom.new
    @easy_room.safe_attributes = params[:easy_room]
    if @easy_room.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to(params[:continue] ? new_easy_room_path : easy_rooms_path)
    else
      render :action => 'new'
    end
  end

  def index
    @easy_rooms = EasyRoom.all
  end

  def show
    respond_to do |format|
      format.html {
        render :layout => 'base'
      }
      format.qr {
        @easy_qr = EasyQr.generate_qr(easy_room_url(@easy_room))
        if request.xhr?
          render :template => 'easy_qr/show', :formats => [:js], :locals => { :modal => true }
        else
          render :template => 'easy_qr/show', :formats => [:html], :content_type => 'text/html'
        end
      }
    end
  end

  def edit
  end

  def update
    @easy_room.safe_attributes = params[:easy_room]
    if @easy_room.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to easy_rooms_path
    else
      render :action => 'edit'
    end
  end

  def destroy
    @easy_room.destroy
    redirect_to easy_rooms_path
  end

  def availability
    @easy_rooms = EasyRoom.all
    render :layout => 'base'
  end

  def meetings
    respond_to do |format|
      format.json { render json: [1, 2, 3] }
    end
  end

  private

  def find_easy_room
    @easy_room = EasyRoom.find(params[:id]) if params[:id]
  end

  def require_easy_room
    render_404 unless @easy_room
  end

end
