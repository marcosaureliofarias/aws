class EasyActionStateActionMailer < EasyBlockMailer

  def new_email(action)
    @body = action.body
    subject = action.subject

    mail(to: action.to, subject: subject) do |format|
      format.html
    end
  end

end
