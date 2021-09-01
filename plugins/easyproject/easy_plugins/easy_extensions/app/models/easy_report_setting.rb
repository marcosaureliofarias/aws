class EasyReportSetting < ActiveRecord::Base

  serialize :settings

  validates :name, :presence => true

  after_save :invalidate_cache
  after_destroy :invalidate_cache

  def invalidate_cache
    if self.name == 'EasyReportIssueStatus'
      RequestStore.store[:status_map_settings] = nil
    end
  end

end
