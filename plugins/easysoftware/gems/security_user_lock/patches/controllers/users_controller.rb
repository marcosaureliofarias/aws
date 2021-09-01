Rys::Patcher.add('UsersController') do

  included do

    def unblock
      find_user(false)

      @user.update_columns(blocked_at: nil, failed_login_attempts: 0)

      respond_to do |format|
        format.html {
          flash[:notice] = user_lock_l('notice_successful_unlock')
          redirect_back_or_default(user_path(@user))
        }
        format.api  { render_api_ok }
      end
    end

  end

end
