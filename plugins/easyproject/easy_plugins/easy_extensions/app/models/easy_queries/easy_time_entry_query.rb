class EasyTimeEntryQuery < EasyTimeEntryBaseQuery

  attr_accessor :only_me

  def query_after_initialize
    super
    self.display_save_button          = true
    self.easy_query_entity_controller = 'easy_time_entries'
  end

  def available_filters
    a = super
    if only_me
      @available_filters.delete('user_id')
    end
    a
  end

  def entity_context_menu_path(options = {})
    easy_time_entries_context_menu_path(options)
  end

  def self.chart_support?
    true
  end

end
