module EasyMeetingsHelper

  def easy_meeting_available_priorities
    [
      [l(:default_priority_high), 'high'],
      [l(:default_priority_normal), 'normal'],
      [l(:default_priority_low), 'low']
    ]
  end

  def easy_meeting_available_privacy
    [
      [l(:field_is_public), 'xpublic'],
      [l(:field_is_private), 'xprivate'],
      [l(:field_is_confidential), 'confidential']
    ]
  end

end
