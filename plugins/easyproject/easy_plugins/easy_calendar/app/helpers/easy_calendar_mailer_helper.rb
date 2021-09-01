module EasyCalendarMailerHelper

  def invitation_subject(meeting)
    if meeting.project
      if meeting.emailed?
        l(:title_meeting_project_invitation_updated, project: meeting.project.name, name: meeting.name)
      else
        "#{meeting.project.name}: #{l(:title_meeting_invitation)}"
      end
    elsif meeting.emailed?
      l(:title_meeting_invitation_updated, name: meeting.name)
    else
      l(:title_meeting_invitation)
    end
  end

end
