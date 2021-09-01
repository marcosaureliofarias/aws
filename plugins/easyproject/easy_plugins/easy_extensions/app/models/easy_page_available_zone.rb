class EasyPageAvailableZone < ActiveRecord::Base

  belongs_to :page_definition, :class_name => 'EasyPage', :foreign_key => 'easy_pages_id'
  belongs_to :zone_definition, :class_name => 'EasyPageZone', :foreign_key => 'easy_page_zones_id'
  has_many :all_modules, :class_name => 'EasyPageZoneModule', :foreign_key => 'easy_page_available_zones_id', :dependent => :destroy

  acts_as_positioned :scope => :easy_pages_id

  validates :easy_pages_id, :presence => true
  validates :easy_page_zones_id, :presence => true

  def self.ensure_easy_page_available_zone(easy_page, easy_page_zone_or_name)
    return false if !easy_page.is_a?(EasyPage)

    if easy_page_zone_or_name.is_a?(EasyPageZone)
      easy_page_zone = easy_page_zone_or_name
    elsif easy_page_zone_or_name.is_a?(String)
      easy_page_zone = EasyPageZone.where(:zone_name => easy_page_zone_or_name).first || EasyPageZone.create(:zone_name => easy_page_zone_or_name)
    end

    return false if easy_page_zone.nil? || easy_page_zone.new_record?

    saved_zone = EasyPageAvailableZone.find_by_easy_pages_id_and_easy_page_zones_id(easy_page.id, easy_page_zone.id)
    EasyPageAvailableZone.create(:easy_pages_id => easy_page.id, :easy_page_zones_id => easy_page_zone.id) if (saved_zone.nil?)
  end

  def self.delete_easy_page_available_zone(easy_page, easy_page_zone)
    saved_zone = EasyPageAvailableZone.find_by_easy_pages_id_and_easy_page_zones_id(easy_page.id, easy_page_zone.id)
    saved_zone.delete unless (saved_zone.nil?)
  end

end


