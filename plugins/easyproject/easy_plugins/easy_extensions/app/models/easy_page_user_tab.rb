class EasyPageUserTab < ActiveRecord::Base

  belongs_to :page_definition, class_name: 'EasyPage', foreign_key: 'page_id'
  belongs_to :user

  acts_as_positioned scope: [:page_id, :user_id, :entity_id]
  acts_as_easy_translate

  store :settings, coder: JSON


  scope :sorted, lambda { order("#{table_name}.position") }
  scope :page_tabs, lambda { |page, user_id, entity_id|
    where(page_id: page, user: user_id, entity_id: entity_id).sorted
  }

  def self.add(page, user, entity_id, **attributes)
    user_id = user && user.id

    tab            = EasyPageUserTab.new(page_id: page.id, user_id: user_id, entity_id: entity_id)
    tab.attributes = attributes

    if tab.name.blank?
      new_count = EasyPageUserTab.page_tabs(page.id, user_id, entity_id).size + 1
      tab.name  = l(:label_easy_page_tab_default_name, count: new_count)
    end

    tab.save!

    if EasyPageUserTab.page_tabs(page.id, user_id, entity_id).where.not(id: tab.id).exists?
      # Not first tab on the page
    else
      # First tab on the page so all modules must be placed under it
      EasyPageZoneModule.where(easy_pages_id: page.id, user_id: user_id, entity_id: entity_id).update_all(tab_id: tab.id)
    end

    tab
  end

  def user_tab_modules(**options)
    page_definition.user_tab_modules(id, user_id, entity_id, **options)
  end

  # @param [String, nil] name
  def copy!(name = nil)
    tab = dup
    self.class.transaction do
      tab.name     = name || self.name.succ
      tab.position += 1
      tab.save!
      copy_modules(tab)
    end
    tab
  end

  # @param [EasyPageUserTab] tab
  def copy_modules_to(tab)
    copy_modules(tab)
    tab
  end

  def easy_page_zone_modules
    @modules ||= EasyPageZoneModule.where(easy_pages_id: page_definition.id, user_id: page_definition.user_id, entity_id: page_definition.entity_id).order(:easy_page_available_zones_id, :position)
  end

  protected

  def copy_modules(tab)
    easy_page_zone_modules.each do |page_module|
      new_module        = page_module.dup
      new_module.tab_id = tab.id
      new_module.save!
    end
  end

end
