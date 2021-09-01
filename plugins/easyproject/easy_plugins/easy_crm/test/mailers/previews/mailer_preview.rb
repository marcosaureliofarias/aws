class MailerPreview < ActionMailer::Preview

  def easy_crm_case_added
    User.current.as_admin do
      EasyCrmMailer.easy_crm_case_added(EasyCrmCase.last)
    end
  end

  def easy_crm_case_updated
    User.current.as_admin do
      EasyCrmMailer.easy_crm_case_updated(EasyCrmCase.last, Journal.last)
    end
  end

end