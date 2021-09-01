Rys::Patcher.add('AccountController') do

  included do
    alias_method :easy_twofa_original_successful_authentication, :successful_authentication

    before_action :setup_easy_twofa_scheme, only: [:easy_twofa_setup, :easy_twofa_verification, :easy_twofa_verify]
  end

  instance_methods do

    def successful_authentication(user)
      if !Rys::Feature.active?('easy_twofa') || user.easy_system_flag
        return super
      end

      mode = EasySetting.value(:easy_twofa_mode)

      # No-one can use twofa
      if mode == 'disabled'
        return super
      end

      @easy_twofa_scheme = EasyTwofa::Auth.for_user(user)

      # Check record in {EasyTwofaRemember}
      if @easy_twofa_scheme&.device_remembered?(request)
        return super
      end

      # Remaining modes behaves in the same way
      if @easy_twofa_scheme&.activated?
        easy_twofa_setup_session(user)
        redirect_to easy_twofa_verification_account_path
        return
      end

      if mode == 'required'
        easy_twofa_setup_session(user, selection: true)
        flash[:warning] = l('easy_twofa.twofa_is_required')
        redirect_to easy_twofa_select_scheme_account_path
      else
        # Twofa is in-active for this user
        super
      end
    end

    def easy_twofa_select_scheme
    end

    def easy_twofa_setup
      # Scheme selection can be done only if mode is "required"
      # and user has no scheme selected. Otherwise users or
      # worse an attacker could change scheme arbitrarily.
      if session[:easy_twofa_selection] != 1
        return render_404
      end

      @easy_twofa_scheme.setup_user_scheme!

      if @easy_twofa_scheme.require_user_setup?
        # Form is rendered
      else
        flash[:notice] = l('easy_twofa.twofa_was_saved')
        redirect_to easy_twofa_verification_account_path
      end
    end

    def easy_twofa_verification
      @easy_twofa_scheme.prepare_verification

      if @easy_twofa_scheme.last_verification_status.success?
        if params[:resend] == '1'
          flash.now[:notice] = l('easy_twofa.code_was_resend')
        end
        render 'account/easy_twofa_verification'
      else
        render 'account/easy_twofa_verification_failed'
      end
    end

    def easy_twofa_verify
      if @easy_twofa_scheme.verify!(params[:verify_code], ignore_activated: (session[:easy_twofa_selection] == 1))
        @easy_twofa_scheme.activate!

        if params[:remember_device] == '1'
          EasyTwofaRemember.remember_device(@easy_twofa_scheme, request)
        end

        easy_twofa_delete_session
        flash[:notice] = l('easy_twofa.successfully_verified')
        easy_twofa_original_successful_authentication(@user)
      elsif session[:easy_twofa_counter] > EasyTwofa.config.max_attempts
        easy_twofa_delete_session
        flash[:error] = l('easy_twofa.too_much_attempts')
        redirect_to signin_path
      else
        session[:easy_twofa_counter] += 1
        flash[:error] = l('easy_twofa.twofa_verification_failed')
        render 'account/easy_twofa_verification'
      end
    end

    private

      def easy_twofa_setup_session(user, selection: false)
        session[:easy_twofa_user_id] = user.id
        session[:easy_twofa_counter] = 0
        session[:easy_twofa_back_url] = params[:back_url]

        if selection
          session[:easy_twofa_selection] = 1
        end
      end

      def easy_twofa_delete_session
        session.delete(:easy_twofa_user_id)
        session.delete(:easy_twofa_counter)
        session.delete(:easy_twofa_back_url)
        session.delete(:easy_twofa_selection)
      end

      def setup_easy_twofa_scheme
        if session.has_key?(:easy_twofa_user_id)
          @user = User.find_by(id: session[:easy_twofa_user_id])
        end

        if @user.nil?
          return render_404
        end

        @easy_twofa_scheme = EasyTwofa::Auth.for_user(@user, params[:scheme_key])

        if @easy_twofa_scheme.nil?
          return render_404
        end

        set_localization(@user)
        params[:back_url] = session[:easy_twofa_back_url]
      end

  end

end
