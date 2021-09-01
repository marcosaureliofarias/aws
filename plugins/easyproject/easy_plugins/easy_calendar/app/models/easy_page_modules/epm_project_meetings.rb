class EpmProjectMeetings < EasyPageModule

  def category_name
    @category_name ||= 'calendars'
  end

  def default_settings
    @default_settings ||= {
      :enabled_calendars => []
    }.with_indifferent_access
  end

end
