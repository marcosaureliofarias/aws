class EasyCalendarMailerPreview < ActionMailer::Preview

  def easy_meeting_invitation
    User.current.as_admin do
      EasyCalendarMailer.easy_meeting_invitation(EasyMeeting.last,'milos@easy.cz')
    end
  end

end
