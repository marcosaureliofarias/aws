class EasyReportIssueStatus < ActiveRecord::Base

  NO_OF_COLUMNS = 29

  belongs_to :issue

  class << self
    def status_map
      EasyReportSetting.find_by(name: 'EasyReportIssueStatus')
    end

    def status_map_settings
      RequestStore.store[:status_map_settings] ||= (self.status_map && self.status_map.settings) || {}
    end

    def get_idx(id)
      self.status_map_settings[:map][id] if id && self.status_map_settings[:map]
    end
  end

  def status_map
    self.class.status_map
  end

  def status_map_settings
    self.class.status_map_settings
  end

  def get_idx(id)
    self.class.get_idx(id)
  end

  def get_status_time(idx)
    read_attribute("status_time_#{idx}") if idx.to_i <= NO_OF_COLUMNS
  end

  def set_status_time(idx, value)
    write_attribute("status_time_#{idx}", value)
  end

  def get_status_count(idx)
    read_attribute("status_count_#{idx}") if idx.to_i <= NO_OF_COLUMNS
  end

  def set_status_count(idx, value)
    write_attribute("status_count_#{idx}", value)
  end

  def set_all_columns_to_nil
    0.upto(NO_OF_COLUMNS).each do |idx|
      set_status_time(idx, nil)
      set_status_count(idx, nil)
    end
  end

end
