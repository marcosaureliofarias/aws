class EasyAttendanceActivitiesController < ApplicationController
  layout 'admin'

  before_action { |c| c.require_admin_or_lesser_admin(:working_time) }
  before_action :find_user, :only => [:set_user_attendace_activity_limits]
  before_action :find_easy_attendance_activity, :only => [:move_attendances, :destroy, :update, :edit, :show]

  def show
  end

  def new
    @easy_attendance_activity = EasyAttendanceActivity.new
  end

  def create
    @easy_attendance_activity                 = EasyAttendanceActivity.new
    @easy_attendance_activity.safe_attributes = params[:easy_attendance_activity]

    if @easy_attendance_activity.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to easy_attendance_settings_path
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      @easy_attendance_activity.safe_attributes = params[:easy_attendance_activity]
      if @easy_attendance_activity.save
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_back_or_default(easy_attendance_settings_path)
        end
        format.api { render_api_ok }
      else
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@easy_attendance_activity) }
      end
    end

  end

  def destroy
    respond_to do |format|
      if @easy_attendance_activity.easy_attendances.any?
        @confirm      = true
        flash[:error] = l(:error_can_not_delete_activity, :scope => :easy_attendance)
        format.html { redirect_to easy_attendance_activity_move_issues_path(@easy_attendance_activity) }
        format.js {
          @easy_attendance_activities = EasyAttendanceActivity.where(["#{EasyAttendanceActivity.table_name}.id <> ?", @easy_attendance_activity.id])
        }
      else
        @easy_attendance_activity.destroy

        format.js {}
        format.html {
          redirect_to easy_attendance_settings_path, :notice => l(:notice_successful_delete)
        }
      end
    end
  end

  def move_attendances
    @easy_attendance_activities = EasyAttendanceActivity.where(["#{EasyAttendanceActivity.table_name}.id <> ?", @easy_attendance_activity.id])

    if request.post? && (params[:easy_attendance_activity_to].present? && params[:easy_attendance_activity_to].to_i != @easy_attendance_activity.id)
      @easy_attendance_activity_to = EasyAttendanceActivity.find(params[:easy_attendance_activity_to])
      @easy_attendance_activity.easy_attendances.update_all(:easy_attendance_activity_id => @easy_attendance_activity_to.id)
      @easy_attendance_activity.reload
      if @easy_attendance_activity.easy_attendances.any?
        flash[:error] = l(:error_can_not_delete_activity, :scope => :easy_attendance)
        redirect_to move_attendances_easy_attendance_activity_path(@easy_attendance_activity)
      else
        flash[:notice] = l(:notice_successful_delete)
        @easy_attendance_activity.destroy
        redirect_to easy_attendance_settings_path
      end
    end
  end

  def reload_time_entry_activities
    mapped_project_id             = params[:easy_attendance_activity].try(:[], :mapped_project_id)
    mapped_time_entry_activity_id = params[:easy_attendance_activity].try(:[], :mapped_time_entry_activity_id)
    if (project = Project.find_by(id: mapped_project_id))
      render :partial => 'easy_attendance_activities/time_entry_activities', :locals => { :project => project, :selected => mapped_time_entry_activity_id }
    else
      render_404
    end
  end

  def set_user_attendace_activity_limits
    unsaved          = []
    user_limits      = params[:easy_attendance_activity_user_limit]
    accumulated_days = params[:easy_attendance_activity_accumulated_days]
    if user_limits
      limits = @user.easy_attendance_activity_user_limits.where(:easy_attendance_activity_id => user_limits.keys).to_a.group_by(&:easy_attendance_activity_id)
      user_limits.each do |activity_id, days|
        limit = limits[activity_id.to_i].first if limits[activity_id.to_i]

        # if empty limit is set, no limit
        if days.blank?
          limit.delete if limit
          next
        end

        limit                  ||= @user.easy_attendance_activity_user_limits.build(:easy_attendance_activity_id => activity_id)
        limit.days             = days.to_f

        limit.accumulated_days = accumulated_days[activity_id].to_f if accumulated_days && accumulated_days[activity_id].present?
        unsaved << limit unless limit.save
      end
    end

    if unsaved.empty?
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = unsaved.map { |i| "#{i.easy_attendance_activity.name}: #{i.errors.full_messages.join(', ')}" }.join('<br>')
    end

    redirect_back_or_default edit_user_path(@user, :tab => 'working_time')
  end

  private

  def find_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_easy_attendance_activity
    @easy_attendance_activity = EasyAttendanceActivity.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
