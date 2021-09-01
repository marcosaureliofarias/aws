class EasyPageTemplateTab < ActiveRecord::Base

  belongs_to :page_template_definition, class_name: 'EasyPageTemplate', foreign_key: 'page_template_id'

  acts_as_positioned scope: [:page_template_id, :entity_id]
  acts_as_easy_translate

  store :settings, coder: JSON


  scope :sorted, lambda { order("#{table_name}.position") }
  scope :page_template_tabs, lambda { |page_template, entity_id|
    where(page_template_id: page_template.id, entity_id: entity_id).sorted
  }

  def self.add(template, entity_id, **attributes)
    tab            = EasyPageTemplateTab.new(page_template_id: template.id, entity_id: entity_id)
    tab.attributes = attributes

    if tab.name.blank?
      new_count = EasyPageTemplateTab.page_template_tabs(template, entity_id).size + 1
      tab.name  = l(:label_easy_page_tab_default_name, count: new_count)
    end

    tab.save!

    if EasyPageTemplateTab.page_template_tabs(template, entity_id).where.not(id: tab.id).exists?
      # Not first tab on the page
    else
      # First tab on the page so all modules must be placed under it
      EasyPageTemplateModule.where(easy_page_templates_id: template.id, entity_id: entity_id).update_all(tab_id: tab.id)
    end

    tab
  end

  def template_tab_modules(**options)
    page_template_definition.template_tab_modules(id, entity_id, **options)
  end

end
