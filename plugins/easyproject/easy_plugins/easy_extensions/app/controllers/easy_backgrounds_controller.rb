class EasyBackgroundsController < ApplicationController

  before_action :find_user, only: [:user_notify]

  def user_notify
    EasyUserChannel.send_message(@user, params[:message])

    head :ok
  end

  private

  def find_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
