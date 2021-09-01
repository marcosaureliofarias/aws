class PasswordController < MyController

  # Manage user's password
  def password
    @user = User.current
    unless @user.change_password_allowed?
      flash[:error] = l(:notice_can_t_change_password)
      redirect_back_or_default my_account_path
      return
    end
    if request.post?
      if !@user.check_password?(params[:password])
        flash.now[:error] = l(:notice_account_wrong_password)
      elsif params[:password] == params[:new_password]
        flash.now[:error] = l(:notice_new_password_must_be_different)
      else
        @user.password, @user.password_confirmation = params[:new_password], params[:new_password_confirmation]
        @user.must_change_passwd                    = false
        if @user.save
          # The session token was destroyed by the password change, generate a new one
          session[:tk] = @user.generate_session_token
          Mailer.deliver_password_updated(@user, User.current)
          flash[:notice] = l(:notice_account_password_updated)
          redirect_back_or_default my_account_path
        end
      end
    end
  end

end