require_relative '../../lib/easy_extensions/easy_page_modules/translatable_settings'

class EasyPageZoneModule < ActiveRecord::Base
  include EasyUtils::BlockUtils
  include Redmine::I18n

  include Redmine::SafeAttributes
  prepend EasyPageModules::TranslatableSettings

  safe_attributes 'tab_id',
                  'tab',
                  'settings',
                  'position',
                  'entity_id',
                  'user_id',
                  'easy_page_available_modules_id',
                  'easy_page_available_zones_id',
                  'easy_pages_id'

  self.primary_key = 'uuid'

  belongs_to :page_definition, class_name: 'EasyPage', foreign_key: 'easy_pages_id'
  belongs_to :available_zone, class_name: 'EasyPageAvailableZone', foreign_key: 'easy_page_available_zones_id'
  belongs_to :available_module, class_name: 'EasyPageAvailableModule', foreign_key: 'easy_page_available_modules_id'
  belongs_to :user, class_name: 'User', foreign_key: 'user_id'
  belongs_to :page_tab, class_name: 'EasyPageUserTab', foreign_key: 'tab_id'
  has_many :easy_chart_baselines, dependent: :destroy, foreign_key: 'page_module_id'
  has_one :zone_definition, class_name: 'EasyPageZone', through: :available_zone
  has_one :module_definition, class_name: 'EasyPageModule', through: :available_module

  has_one :easy_query_snapshot, foreign_key: 'epzm_uuid', dependent: :destroy

  accepts_nested_attributes_for :easy_query_snapshot, allow_destroy: true

  validates_presence_of :easy_pages_id, :easy_page_available_zones_id, :easy_page_available_modules_id

  acts_as_positioned

  store :settings, coder: JSON

  attr_accessor :css_class, :new_on_page

  before_save :generate_module_uuid
  before_create :set_new_on_page
  after_update :invalidate_cache
  after_destroy :invalidate_cache

  delegate :caching_available?, :max_row_limit, to: :module_definition, allow_nil: true

  def self.delete_modules(easy_page, user_id = nil, entity_id = nil, tab_id = nil, force = false)
    return unless easy_page.is_a?(EasyPage)

    epzm_scope = EasyPageZoneModule.where(:easy_pages_id => easy_page.id, :user_id => user_id.presence, :entity_id => entity_id.presence)
    epzm_scope = epzm_scope.where(tab_id: tab_id) if tab_id

    if EasyPageUserTab.page_tabs(easy_page.id, user_id, entity_id).count == 1 && !force
      epzm_scope.update_all(tab_id: nil)
    else
      epzm_scope.delete_all
    end

    if !tab_id.nil? && EasyPageUserTab.table_exists?
      EasyPageUserTab.destroy(tab_id)
    end
  end

  def self.create_from_page_template(page_template, user_id = nil, entity_id = nil)
    return unless page_template.is_a?(EasyPageTemplate)

    easy_page = page_template.page_definition

    EasyPageZoneModule.delete_modules(easy_page, user_id, entity_id, nil, true)

    EasyPageUserTab.where(page_id: easy_page.id, user_id: user_id, entity_id: entity_id).destroy_all

    tab_id_mapping = {}

    if EasyPageTemplateTab.table_exists?
      EasyPageTemplateTab.page_template_tabs(page_template, nil).each do |page_template_tab|
        page_tab = EasyPageUserTab.new(page_id:        easy_page.id,
                                       user_id:        user_id,
                                       entity_id:      entity_id,
                                       name:           page_template_tab.name(translated: false),
                                       settings:       page_template_tab.settings,
                                       mobile_default: page_template_tab.mobile_default)
        page_template_tab.copy_translations(page_tab)
        page_tab.save!
        tab_id_mapping[page_template_tab.id] = page_tab.id
      end
    end

    EasyPageTemplateModule.where(easy_page_templates_id: page_template.id).order(:easy_page_available_zones_id, :position).all.each do |template_module|
      template_module.do_not_translate = true
      page_module                      = if EasyPageUserTab.table_exists?
                                           EasyPageZoneModule.new(easy_pages_id:                  easy_page.id,
                                                                  easy_page_available_zones_id:   template_module.easy_page_available_zones_id,
                                                                  easy_page_available_modules_id: template_module.easy_page_available_modules_id,
                                                                  user_id:                        user_id,
                                                                  entity_id:                      entity_id,
                                                                  position:                       template_module.position,
                                                                  settings:                       template_module.settings,
                                                                  tab_id:                         tab_id_mapping[template_module.tab_id])
                                         else
                                           EasyPageZoneModule.new(easy_pages_id:                  easy_page.id,
                                                                  easy_page_available_zones_id:   template_module.easy_page_available_zones_id,
                                                                  easy_page_available_modules_id: template_module.easy_page_available_modules_id,
                                                                  user_id:                        user_id, entity_id: entity_id, position: template_module.position,
                                                                  settings:                       template_module.settings)
                                         end

      page_module.save!
    end
  end

  def self.add_from_page_template(page_template, user = nil, entity_id = nil)
    return unless page_template.is_a?(EasyPageTemplate)

    page_template.create_page(user, entity_id)
  end

  # Keep `options` for future.
  # Options:
  #   * query_mapping: for changing old query id in module setting
  def self.clone_by_entity_id(old_entity_id, new_entity_id, options = {})
    tab_mapping   = {}
    query_mapping = options[:query_mapping] || {}

    EasyPageUserTab.where(:entity_id => old_entity_id).order(:page_id, :position).all.each do |old_tab|
      new_tab           = old_tab.dup
      new_tab.entity_id = new_entity_id
      new_tab.save!

      tab_mapping[old_tab.id] = new_tab.id
    end

    EasyPageZoneModule.where(:entity_id => old_entity_id).order(:easy_page_available_zones_id, :position).all.each do |old_page_module|
      new_page_module           = old_page_module.dup
      new_page_module.entity_id = new_entity_id
      new_page_module.generate_module_uuid(true)
      new_page_module.tab_id = tab_mapping[old_page_module.tab_id]

      # Map old query_id to new query_id (only for query modules)
      if old_page_module.module_definition.query_module? && (old_query_id = old_page_module.settings[:query_id]) && (new_query_id = query_mapping[old_query_id])
        new_page_module.settings[:query_id] = new_query_id
      end

      new_page_module.save!
    end

  end

  def easy_page_tabs_available
    EasyPageUserTab.page_tabs(page_definition, user_id, entity_id)
  end

  def position_scope
    cond = "#{EasyPageZoneModule.table_name}.easy_pages_id = #{self.easy_pages_id} AND #{EasyPageZoneModule.table_name}.easy_page_available_zones_id = #{self.easy_page_available_zones_id}"
    cond << (self.tab_id.blank? ? " AND #{EasyPageZoneModule.table_name}.tab_id IS NULL" : " AND #{EasyPageZoneModule.table_name}.tab_id = #{self.tab_id}")
    cond << (self.user_id.blank? ? " AND #{EasyPageZoneModule.table_name}.user_id IS NULL" : " AND #{EasyPageZoneModule.table_name}.user_id = #{self.user_id}")
    cond << (self.entity_id.blank? ? " AND #{EasyPageZoneModule.table_name}.entity_id IS NULL" : " AND #{EasyPageZoneModule.table_name}.entity_id = #{self.entity_id}")
    self.class.where(cond)
  end

  def position_scope_was
    method                            = destroyed? ? '_was' : '_before_last_save'
    tab_id_prev                       = send('tab_id' + method)
    user_id_prev                      = send('user_id' + method)
    entity_id_prev                    = send('entity_id' + method)
    easy_pages_id_prev                = send('easy_pages_id' + method)
    easy_page_available_zones_id_prev = send('easy_page_available_zones_id' + method)

    cond = "#{EasyPageZoneModule.table_name}.easy_pages_id = #{easy_pages_id_prev} AND #{EasyPageZoneModule.table_name}.easy_page_available_zones_id = #{easy_page_available_zones_id_prev}"
    cond << (tab_id_prev.blank? ? " AND #{EasyPageZoneModule.table_name}.tab_id IS NULL" : " AND #{EasyPageZoneModule.table_name}.tab_id = #{tab_id_prev}")
    cond << (user_id_prev.blank? ? " AND #{EasyPageZoneModule.table_name}.user_id IS NULL" : " AND #{EasyPageZoneModule.table_name}.user_id = #{user_id_prev}")
    cond << (entity_id_prev.blank? ? " AND #{EasyPageZoneModule.table_name}.entity_id IS NULL" : " AND #{EasyPageZoneModule.table_name}.entity_id = #{entity_id_prev}")
    self.class.where(cond)
  end

  def generate_module_uuid(force = false)
    if force
      self.uuid = EasyUtils::UUID.generate.dasherize
    else
      self.uuid ||= EasyUtils::UUID.generate.dasherize
    end
  end

  def module_name
    @module_name ||= "#{self.module_definition.module_name.underscore}_#{self.uuid.underscore}"
  end

  def get_settings(params_settings = nil)
    s = default_settings.merge(settings)
    if params_settings.nil?
      params_settings = {}
    else
      params_settings = params_settings.to_unsafe_hash
    end
    s.merge!(params_settings)
    s.delete('user_id')
    s
  end

  # proxy
  def get_show_data(user, params_settings = nil, page_context = {})
    module_definition.page_zone_module = self
    module_definition.get_show_data(get_settings(params_settings), user, page_context || {}) || {}
  end

  # proxy
  def get_edit_data(user, params_settings = nil, page_context = {})
    module_definition.page_zone_module = self
    module_definition.get_edit_data(get_settings(params_settings), user, page_context || {}) || {}
  end

  # proxy
  def chart_included?
    module_definition.chart_included?(get_settings(nil))
  end

  # proxy
  def cache_on?
    module_definition.page_zone_module = self
    module_definition.cache_on?(get_settings(nil))
  end

  def module_cache_key(*args)
    key_args = args.map { |a| a.try(:cache_key) || a.to_param }.join('/')
    "EasyPageZoneModule/#{id}/#{key_args}"
  end

  def floating?
    @floating.nil? ? false : @floating
  end

  def floating=(value)
    @floating = value
  end

  def from_params(params = nil)
    params ||= {}
    params = params.to_unsafe_hash if params.respond_to?(:to_unsafe_hash)
    module_definition.before_from_params(self, params)
    write_attribute(:settings, (self.settings || {}).merge(params))
  end

  def before_save
    module_definition.page_zone_module_before_save(self)
  end

  def after_load
    module_definition.page_zone_module_after_load(self)
  end

  def snapshot_supported?
    module_definition&.snapshot_supported?
  end

  def snapshot?
    settings['daily_snapshot'] == '1'
  end

  def snapshot_initialized?
    self.easy_query_snapshot.present?
  end

  private

  def default_settings
    {
        'query_type' => '2',
        'query_name' => l('easy_page_module.issue_query.adhoc_query_default_text')
    }
  end

  def invalidate_cache
    if caching_available?
      # This could be very slow
      # TODO: Make it faster
      begin
        Rails.cache.delete_matched(Regexp.new("^EasyPageZoneModule/#{id}"))
      rescue NotImplementedError
      end
    end
  end

  def set_new_on_page
    self.new_on_page = true
  end
end

