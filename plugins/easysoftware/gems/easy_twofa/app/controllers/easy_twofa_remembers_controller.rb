# frozen_string_literal: true

class EasyTwofaRemembersController < ApplicationController

  before_action :require_login
  before_action :find_user, only: [:index]
  before_action :find_remember, only: [:destroy]

  def index
    @remembers = @user.easy_twofa_scheme&.remembers&.ordered
  end

  def destroy
    @remember.destroy

    flash[:notice] = l(:notice_successful_delete)
    redirect_back_or_default remembers_easy_twofa_path(user_id: @remember.user_scheme.user_id)
  end

  private

    def find_user
      if params[:user_id].present?
        user_id = params[:user_id].to_i

        if User.current.admin?
          # OK
        elsif User.current.id == user_id
          # OK
        else
          return render_403
        end
      else
        user_id = User.current.id
      end

      @user = User.preload(easy_twofa_scheme: :remembers).find_by(id: user_id)

      if @user.nil?
        return render_404
      end
    end

    def find_remember
      @remember = EasyTwofaRemember.preload(:user_scheme).find_by(id: params[:id])

      if @remember.nil?
        return render_404
      end

      if User.current.admin?
        # OK
      elsif @remember.user_scheme.user_id == User.current.id
        # OK
      else
        return render_403
      end
    end

end
