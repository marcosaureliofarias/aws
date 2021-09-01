class EasyMeetingsController < ApplicationController

  accept_api_auth :create, :update, :destroy, :accept, :decline, :show

  before_action :authorize_global

  before_action :find_easy_meeting, only: [:show, :edit, :update, :destroy, :accept, :decline]

  before_action :check_visible, only: [:show, :accept, :decline, :edit, :update, :destroy]
  before_action :check_editable, only: [:edit, :update, :destroy]

  before_action :validate_meeting, only: [:edit, :show], if: -> { request.format.html? }

  def new
    @easy_meeting = EasyMeeting.new
    @easy_meeting.safe_attributes = params[:easy_meeting] if params[:easy_meeting]
    render :layout => !request.xhr?
  end

  def create
    @easy_meeting = EasyMeeting.new
    @easy_meeting.safe_attributes = params[:easy_meeting]
    if @easy_meeting.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_to action: :new
        end
        format.api { render action: :show, status: 201 }
      end
    else
      respond_to do |format|
        format.html { render action: :new }
        format.api { render_validation_errors @easy_meeting }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html {render :layout => !request.xhr?}
      format.js
    end
  end

  def update
    @easy_meeting.safe_attributes = params[:easy_meeting] if params[:easy_meeting]
    if @easy_meeting.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_to action: :show
        end
        format.api { render action: :show }
      end
    else
      respond_to do |format|
        format.html { render action: :edit }
        format.api { render_validation_errors @easy_meeting }
      end
    end
  end

  def show
    respond_to do |format|
      format.html {render :layout => !request.xhr?}
      format.js
      format.api
    end
  end

  def destroy
    easy_invitations = @easy_meeting.easy_invitations.where(accepted: true).to_a
    if params[:repeating] || @easy_meeting.big_recurring?
      removed = @easy_meeting.destroy_all_repeated
    elsif params[:current_and_following]
      removed = @easy_meeting.destroy_current_and_following_repeated
    else
      removed = @easy_meeting.destroy
    end
    @easy_meeting.send_notification_about_removal(easy_invitations) if @easy_meeting.destroyed? || (removed && removed.first.destroyed?)

    respond_to do |format|
      format.api {render_api_ok}
      format.js
    end
  end

  def accept
    @easy_meeting.reflect_on_big_recurring_childs = params[:reflect_on_big_recurring_childs]
    @easy_meeting.accept!
    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_update)
        redirect_back_or_default action: 'show'
      }
      format.api {render_api_ok}
    end
  end

  def decline
    @easy_meeting.reflect_on_big_recurring_childs = params[:reflect_on_big_recurring_childs]
    @easy_meeting.decline!
    respond_to do |format|
      format.html {
        flash[:notice] = l(:notice_successful_update)
        redirect_back_or_default action: 'show'
      }
      format.api {render_api_ok}
    end
  end

  private

  def find_easy_meeting
    @easy_meeting = EasyMeeting.preload(easy_invitations: :user).find(params[:id]) if params[:id]
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def validate_meeting
    @easy_meeting.validate_room_conflicts
  end

  def check_visible
    return render_403 unless @easy_meeting.visible?
  end

  def check_editable
    return render_403 unless @easy_meeting.editable?
  end
end
