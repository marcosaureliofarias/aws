class EasyPageTemplate < ActiveRecord::Base
  self.table_name = 'easy_page_templates'
  include Redmine::SafeAttributes

  safe_attributes 'easy_pages_id',
                  'template_name',
                  'description',
                  'is_default',
                  'position',
                  'reorder_to_position',
                  'copy_from_type',
                  'copy_from_user_id',
                  'copy_from_entity_id',
                  'copy_from_template_id',
                  'copy_from_tab_id'

  default_scope { order("#{EasyPageTemplate.table_name}.position ASC") }

  belongs_to :page_definition, :class_name => 'EasyPage', :foreign_key => 'easy_pages_id'
  has_many :easy_page_template_modules, :class_name => 'EasyPageTemplateModule', :foreign_key => 'easy_page_templates_id'
  has_many :easy_page_template_tabs, :class_name => 'EasyPageTemplateTab', :foreign_key => 'page_template_id', :dependent => :destroy

  has_many :easy_user_types, inverse_of: :default_page_template, dependent: :nullify

  scope :sorted, -> { order(:position) }

  acts_as_positioned :scope => :easy_pages_id

  validates_length_of :template_name, :in => 1..50, :allow_nil => false
  validates_length_of :description, :in => 0..255, :allow_nil => true

  # Create template from existing page
  # {copy_from_type} is there because user_id and entity_id could be nil
  attr_accessor :copy_from_type, :copy_from_user_id, :copy_from_entity_id, :copy_from_template_id, :copy_from_tab_id

  before_save :check_default
  after_save :copy_from_existing

  def self.default_template_for_page(page)
    return nil unless page.is_a?(EasyPage)
    EasyPageTemplate.find_by(:easy_pages_id => page.id, :is_default => true)
  end

  def copy_from_existing?
    copy_from_type.present? && page_definition && page_definition.has_template?
  end

  def template_modules(entity_id = nil, options = {})
    if (tab = options[:tab])
      tab = tab.to_i
      tab = 1 if tab <= 0
    end

    template_tab_modules(tab, entity_id, options)
  end

  def template_tab_modules(page_tab, entity_id = nil, options = {})
    scope = EasyPageTemplateModule.preload(:zone_definition, :module_definition).order(position: :asc)
    scope = scope.where(entity_id: entity_id, easy_page_templates_id: self)
    scope = scope.where(tab_id: page_tab) unless options[:all_tabs]

    all_modules = scope.select { |mod| mod.module_definition&.module_allowed? }

    if options[:without_zones]
      all_modules
    else
      template_modules = page_definition.zones.joins(:zone_definition).pluck(:zone_name).each_with_object({}) { |zone_name, result| result[zone_name] = [] }
      template_modules.merge!(all_modules.group_by { |mod| mod.zone_definition.zone_name })
      template_modules
    end
  end

  def create_page(user = nil, entity_id = nil)
    tab_id_mapping = create_tabs(user, entity_id)
    create_modules(tab_id_mapping, user&.id, entity_id)
  end

  private

  def create_tabs(user = nil, entity_id = nil)
    tab_id_mapping = {}

    if (tabs = easy_page_template_tabs).any?
      tabs.each do |tab|
        page_tab = EasyPageUserTab.new(page_id: page_definition.id, user_id: user&.id, entity_id: entity_id, name: tab.name, settings: tab.settings)
        page_tab.save!
        tab_id_mapping[tab.id] = page_tab.id
      end
    else
      new_tab                   = EasyPageUserTab.add(page_definition, user, entity_id)
      tab_id_mapping['new_tab'] = new_tab.id
    end
    tab_id_mapping
  end

  def create_modules(tab_id_mapping, user_id = nil, entity_id = nil)

    easy_page_template_modules.order(:easy_page_available_zones_id, :position).each do |template_module|
      page_module = EasyPageZoneModule.new(easy_pages_id:                  page_definition.id,
                                           easy_page_available_zones_id:   template_module.easy_page_available_zones_id,
                                           easy_page_available_modules_id: template_module.easy_page_available_modules_id,
                                           user_id:                        user_id,
                                           entity_id:                      entity_id,
                                           position:                       template_module.position,
                                           settings:                       template_module.settings,
                                           tab_id:                         tab_id_mapping[template_module.tab_id] || tab_id_mapping['new_tab'])

      page_module.save!
    end
  end

  def check_default
    if is_default? && is_default_changed?
      EasyPageTemplate.where(:easy_pages_id => self.easy_pages_id).update_all(:is_default => false)
    end
  end

  def copy_from_existing
    return unless copy_from_existing?

    # Just for sure
    easy_page_template_modules.destroy_all
    easy_page_template_tabs.destroy_all

    case copy_from_type
    when 'template'
      copy_from_existing_template
    when 'regular_page'
      copy_from_existing_regular_page
    end
  end

  def copy_from_existing_template
    template = EasyPageTemplate.find_by_id(copy_from_template_id)
    return unless template

    # Copying easy_page_template tabs
    tab_id_mapping = {}
    template.easy_page_template_tabs.sorted.each do |template_tab|
      new_template_tab = easy_page_template_tabs.build(name:           template_tab.name(translated: false),
                                                       settings:       template_tab.settings,
                                                       mobile_default: template_tab.mobile_default)
      template_tab.copy_translations(new_template_tab)
      new_template_tab.save!

      tab_id_mapping[template_tab.id] = new_template_tab.id
    end

    # Copy easy_page_template modules
    template_modules = template.easy_page_template_modules.order(:easy_page_available_zones_id, :position)
    template_modules.each do |template_module|
      new_template_module = easy_page_template_modules.build(
          easy_page_available_zones_id:   template_module.easy_page_available_zones_id,
          easy_page_available_modules_id: template_module.easy_page_available_modules_id,
          position:                       template_module.position,
          settings:                       template_module.settings,
          tab_id:                         tab_id_mapping[template_module.tab_id]
      )
      new_template_module.save!
    end
  end

  def copy_from_existing_regular_page
    # Could be empty string
    from_user_id   = copy_from_user_id.presence
    from_entity_id = copy_from_entity_id.presence
    from_tab_id = copy_from_tab_id.presence

    # Copying easy_page tabs
    tab_id_mapping = {}
    page_tabs = EasyPageUserTab.page_tabs(page_definition, from_user_id, from_entity_id)
    page_tabs = page_tabs.where(id: from_tab_id) if from_tab_id
    page_tabs.each do |user_tab|
      template_tab = easy_page_template_tabs.build(
          name:           user_tab.name(translated: false),
          settings:       user_tab.settings,
          mobile_default: user_tab.mobile_default
      )
      user_tab.copy_translations(template_tab)
      template_tab.save!

      tab_id_mapping[user_tab.id] = template_tab.id
    end

    # Copy easy_page modules
    page_modules = EasyPageZoneModule.where(easy_pages_id: page_definition.id, user_id: from_user_id, entity_id: from_entity_id).order(:easy_page_available_zones_id, :position)
    page_modules = page_modules.where(tab_id: from_tab_id) if from_tab_id
    page_modules.each do |page_module|
      template_module = easy_page_template_modules.build(
          easy_page_available_zones_id:   page_module.easy_page_available_zones_id,
          easy_page_available_modules_id: page_module.easy_page_available_modules_id,
          position:                       page_module.position,
          settings:                       page_module.settings,
          tab_id:                         tab_id_mapping[page_module.tab_id]
      )
      template_module.save!
    end
  end

end
