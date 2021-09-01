class EmailFieldAutocompleteController < ApplicationController

  USERS_LIMIT = 15

  def find
    result = []

    users = User.visible.active.preload(:email_address).like(params[:term]).limit(USERS_LIMIT)

    users.each do |user|
      result << {
        id: user.mail,
        name: user.name,
        label: user.mail
      }
    end

    respond_to do |format|
      format.json { render json: result }
    end
  end

end
