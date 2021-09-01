require 'rqrcode'

class EasyTwofaController < ApplicationController

  before_action :require_login
  before_action :require_admin, only: [:setting, :save_setting, :admin_disable]
  before_action :setup_scheme, only: [:setup, :activation, :activate, :disable, :disable_confirm, :admin_disable]

  def setting
    render layout: 'admin'
  end

  def save_setting
    easy_settings = EasySettings::ParamsWrapper.from_params(params[:setting].permit!, prefix: 'easy_twofa')

    # For now there are no custom validation
    easy_settings.save

    flash[:notice] = l(:notice_successful_update)
    redirect_to setting_easy_twofa_path
  end

  def setup
    @scheme.setup_user_scheme!

    if @scheme.require_user_setup?
      # Form is rendered
    else
      flash[:notice] = l('easy_twofa.twofa_was_saved')
      redirect_to activation_easy_twofa_path
    end
  end

  def activation
    prepare_verification
  end

  def activate
    if @scheme.verify!(params[:verify_code], ignore_activated: true)
      @scheme.activate!
      flash[:notice] = l('easy_twofa.successfully_verified')
      redirect_to my_account_path
    else
      flash[:error] = l('easy_twofa.twofa_verification_failed')
      render 'easy_twofa/activation'
    end
  end

  def disable
    prepare_verification
  end

  def disable_confirm
    if @scheme.verify!(params[:verify_code])
      @scheme.disable!
      flash[:notice] = l('easy_twofa.successfully_disabled')
      redirect_to my_account_path
    else
      flash[:error] = l('easy_twofa.twofa_verification_failed')
      render 'easy_twofa/disable'
    end
  end

  def admin_disable
    user = User.find_by(id: params[:user_id])

    if user.nil?
      return render_404
    end

    scheme = EasyTwofa::Auth.for_user(user)
    scheme&.disable!

    flash[:notice] = l('easy_twofa.successfully_disabled')
    redirect_to edit_user_path(@user)
  end

  private

    def prepare_verification
      @scheme.prepare_verification

      if @scheme.last_verification_status.success?
        if params[:resend] == '1'
          flash.now[:notice] = l('easy_twofa.code_was_resend')
        end
      else
        render 'prepare_verification_failed'
      end
    end

    def setup_scheme
      if params[:user_id].present? && User.current.admin?
        @user = User.find_by(id: params[:user_id])
      else
        @user = User.current
      end

      if @user.nil?
        return render_404
      end

      @scheme = EasyTwofa::Auth.for_user(@user, params[:scheme_key])

      if @scheme.nil?
        return render_404
      end
    end

end
