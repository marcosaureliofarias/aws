require_relative '../../lib/easy_extensions/easy_page_modules/translatable_settings'

class EasyPageTemplateModule < ActiveRecord::Base
  include EasyUtils::BlockUtils
  include Redmine::I18n
  extend EasyUtils::BlockUtils

  prepend EasyPageModules::TranslatableSettings

  self.primary_key = 'uuid'

  belongs_to :template_definition, :class_name => 'EasyPageTemplate', :foreign_key => 'easy_page_templates_id'
  belongs_to :available_zone, :class_name => 'EasyPageAvailableZone', :foreign_key => 'easy_page_available_zones_id'
  belongs_to :available_module, :class_name => 'EasyPageAvailableModule', :foreign_key => 'easy_page_available_modules_id'
  belongs_to :page_tab, class_name: 'EasyPageTemplateTab', foreign_key: 'tab_id'
  has_one :page_definition, :class_name => 'EasyPage', :through => :template_definition
  has_one :zone_definition, :class_name => 'EasyPageZone', :through => :available_zone
  has_one :module_definition, :class_name => 'EasyPageModule', :through => :available_module

  has_one :easy_query_snapshot, foreign_key: 'epzm_uuid', dependent: :destroy

  accepts_nested_attributes_for :easy_query_snapshot, allow_destroy: true

  validates_presence_of :easy_page_templates_id, :easy_page_available_zones_id, :easy_page_available_modules_id


  acts_as_positioned

  store :settings, coder: JSON

  attr_accessor :css_class, :new_on_page

  before_save :generate_module_uuid
  before_create :set_new_on_page

  delegate :caching_available?, :max_row_limit, to: :module_definition, allow_nil: true

  def self.delete_modules(easy_page_template, entity_id = nil, tab_id = nil)
    return unless easy_page_template.is_a?(EasyPageTemplate)

    eptm_scope = EasyPageTemplateModule.all
    eptm_scope = eptm_scope.where(:easy_page_templates_id => easy_page_template.id, :entity_id => entity_id.presence)
    eptm_scope = eptm_scope.where(:tab_id => tab_id) if tab_id

    eptm_scope.delete_all

    if !tab_id.nil? && EasyPageTemplateTab.table_exists?
      # eptt_scope = EasyPageTemplateTab.all
      # eptt_scope = eptt_scope.where(:page_template_id => easy_page_template.id)
      # if entity_id.blank?
      #   eptt_scope = eptt_scope.where(:entity_id => nil)
      # else
      #   eptt_scope = eptt_scope.where(:entity_id => entity_id)
      # end

      # eptt_scope.delete_all
      EasyPageTemplateTab.where(:id => tab_id).destroy_all
    end
  end

  def self.create_template_module(page, page_template, page_module, zone_name, settings, position)
    return nil unless page.is_a?(EasyPage)
    return nil unless page_template.is_a?(EasyPageTemplate)
    return nil unless page_module.is_a?(EasyPageModule)

    page_available_module_id = EasyPageAvailableModule.where(:easy_pages_id => page.id, :easy_page_modules_id => page_module.id).limit(1).pluck(:id).first
    page_zone_id             = EasyPageZone.where(:zone_name => zone_name).limit(1).pluck(:id).first
    page_available_zone_id   = EasyPageAvailableZone.where(:easy_pages_id => page.id, :easy_page_zones_id => page_zone_id).limit(1).pluck(:id).first

    EasyPageTemplateModule.create(:easy_page_templates_id => page_template.id, :easy_page_available_zones_id => page_available_zone_id, :easy_page_available_modules_id => page_available_module_id, :uuid => EasyUtils::UUID.generate, :entity_id => nil, :settings => settings, :position => position)
  end

  def easy_page_tabs_available
    EasyPageTemplateTab.page_template_tabs(template_definition, entity_id)
  end

  def position_scope
    cond = "#{EasyPageTemplateModule.table_name}.easy_page_templates_id = #{self.easy_page_templates_id} AND #{EasyPageTemplateModule.table_name}.easy_page_available_zones_id = #{self.easy_page_available_zones_id}"
    cond << (self.tab_id.blank? ? " AND #{EasyPageTemplateModule.table_name}.tab_id IS NULL" : " AND #{EasyPageTemplateModule.table_name}.tab_id = #{self.tab_id}")
    cond << (self.entity_id.blank? ? " AND #{EasyPageTemplateModule.table_name}.entity_id IS NULL" : " AND #{EasyPageTemplateModule.table_name}.entity_id = #{self.entity_id}")
    self.class.where(cond)
  end

  def position_scope_was
    method                            = destroyed? ? '_was' : '_before_last_save'
    easy_page_templates_id_prev       = send('easy_page_templates_id' + method)
    easy_page_available_zones_id_prev = send('easy_page_available_zones_id' + method)
    tab_id_prev                       = send('tab_id' + method)
    entity_id_prev                    = send('entity_id' + method)

    cond = "#{EasyPageTemplateModule.table_name}.easy_page_templates_id = #{easy_page_templates_id_prev} AND #{EasyPageTemplateModule.table_name}.easy_page_available_zones_id = #{easy_page_available_zones_id_prev}"
    cond << (tab_id_prev.blank? ? " AND #{EasyPageTemplateModule.table_name}.tab_id IS NULL" : " AND #{EasyPageTemplateModule.table_name}.tab_id = #{tab_id_prev}")
    cond << (entity_id_prev.blank? ? " AND #{EasyPageTemplateModule.table_name}.entity_id IS NULL" : " AND #{EasyPageTemplateModule.table_name}.entity_id = #{entity_id_prev}")
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
    module_definition.template_zone_module = self
    module_definition.get_show_data(get_settings(params_settings), user, page_context || {})
  end

  # proxy
  def get_edit_data(user, params_settings = nil, page_context = {})
    module_definition.template_zone_module = self
    module_definition.get_edit_data(get_settings(params_settings), user, page_context || {})
  end

  # proxy
  def chart_included?
    false
  end

  def cache_on?
    false
  end

  def module_cache_key(*args)
    "EasyPageTemplateModule/#{id}"
  end

  def floating?
    @floating.nil? ? false : @floating
  end

  def floating=(value)
    @floating = value
  end

  def from_params(params = nil)
    params = params.to_unsafe_hash if params.respond_to?(:to_unsafe_hash)
    write_attribute(:settings, (self.settings || {}).merge(params || {}))
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

  private

  def default_settings
    {
        'query_type' => '2',
        'query_name' => l('easy_page_module.issue_query.adhoc_query_default_text')
    }
  end

  def set_new_on_page
    self.new_on_page = true
  end
end

