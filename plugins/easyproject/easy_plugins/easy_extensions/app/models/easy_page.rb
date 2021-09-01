class EasyPage < ActiveRecord::Base
  include Redmine::SafeAttributes
  include EasyPatch::ActsAsEasyJournalized

  CUSTOM_PAGE           = 'easy-custom'
  IDENTIFIER_MAX_LENGTH = 100
  PAGE_LAYOUTS          = {
      'tchtrrs' => {
          :path  => 'easy_page_layouts/two_column_header_three_rows_right_sidebar',
          :zones => ['top-left', 'middle-left', 'middle-right', 'bottom-left', 'right-sidebar'] },
      'tchfw'   => {
          :path  => 'easy_page_layouts/two_column_header_first_wider',
          :zones => ['top-middle', 'middle-left', 'middle-right'] },
      'tchaf'   => {
          :path  => 'easy_page_layouts/two_column_header_and_footer',
          :zones => ['top-middle', 'middle-left', 'middle-right', 'middle2-left', 'middle2-right', 'middle3-left', 'middle3-right', 'mini-middle3-1', 'mini-middle3-2', 'mini-middle3-3', 'mini-middle4-1', 'mini-middle4-2', 'mini-middle4-3', 'mini-middle4-4', 'mini-middle5-1', 'mini-middle5-2', 'mini-middle5-3', 'mini-middle5-4', 'mini-middle5-5', 'bottom-middle'] }
  }

  belongs_to :user

  has_many :zones, -> { preload(:zone_definition).order("#{EasyPageAvailableZone.table_name}.position ASC") }, class_name: 'EasyPageAvailableZone', foreign_key: 'easy_pages_id', dependent: :destroy
  has_many :modules, -> { preload(:module_definition) }, class_name: 'EasyPageAvailableModule', foreign_key: 'easy_pages_id', dependent: :destroy
  has_many :templates, class_name: 'EasyPageTemplate', foreign_key: 'easy_pages_id', dependent: :destroy

  has_many :all_modules, through: :zones
  has_many :easy_page_tabs, class_name: 'EasyPageUserTab', foreign_key: 'page_id', dependent: :destroy

  # permissions
  has_many :easy_page_permissions, -> { permission_edit }, after_add: :journalize_change, after_remove: :journalize_change, dependent: :destroy
  has_many :permitted_principals, through: :easy_page_permissions, source: :entity, source_type: 'Principal', after_add: :journalize_change, after_remove: :journalize_change, dependent: :destroy
  has_many :permitted_easy_user_types, through: :easy_page_permissions, source: :entity, source_type: 'EasyUserType', after_add: :journalize_change, after_remove: :journalize_change, dependent: :destroy
  has_many :easy_page_show_permissions, -> { permission_show }, class_name: 'EasyPagePermission', after_add: :journalize_change, after_remove: :journalize_change, dependent: :destroy
  has_many :permitted_show_principals, through: :easy_page_show_permissions, source: :entity, source_type: 'Principal', after_add: :journalize_change, after_remove: :journalize_change, dependent: :destroy
  has_many :permitted_show_easy_user_types, through: :easy_page_show_permissions, source: :entity, source_type: 'EasyUserType', after_add: :journalize_change, after_remove: :journalize_change, dependent: :destroy

  scope :for_index, -> {
    where(["(#{table_name}.has_template = ? AND #{table_name}.page_scope IN (?)) OR #{table_name}.is_user_defined = ?", true, [:user, :project], true])
  }
  scope :built_in, -> { where(built_in_conditions) }

  acts_as_taggable_on :tags
  acts_as_easy_journalized format_detail_boolean_columns: %w(strict_permissions strict_show_permissions)

  EasyExtensions::EasyTag.register self, { :easy_query_class => 'EasyPageQuery', :referenced_collection_name => 'easy_pages' }

  validates_length_of :page_name, in: 1..50, allow_nil: false
  validates_length_of :user_defined_name, in: 1..50, allow_blank: true, unless: -> { built_in? }
  validates_length_of :description, maximum: 255
  validates_uniqueness_of :identifier, allow_blank: true, scope: [:entity_type, :entity_id, :user_id], if: proc { EasyPage.column_names.include?('identifier') }
  validates_length_of :identifier, allow_blank: true, in: 1..IDENTIFIER_MAX_LENGTH, if: proc { EasyPage.column_names.include?('identifier') }
  validates_format_of :identifier, with: /\A(?!\d+$)[a-z0-9\-_]*\z/, if: proc { |p| EasyPage.column_names.include?('identifier') && p.identifier_changed? }
  validates_exclusion_of :identifier, in: %w(index show new create edit update destroy templates), if: proc { EasyPage.column_names.include?('identifier') }
  validates :layout_path, inclusion: PAGE_LAYOUTS.collect { |_, v| v[:path] }

  before_save :change_page_name
  after_save :ensure_available_page_zones
  after_save :create_journal, if: proc { |p| p.page_scope.nil? }

  safe_attributes 'identifier', 'user_defined_name', 'description', 'tag_list',
                  'permitted_principal_ids', 'permitted_easy_user_type_ids', 'strict_permissions',
                  'permitted_show_principal_ids', 'permitted_show_easy_user_type_ids', 'strict_show_permissions'

  @easy_pages = {}

  def self.find_similiar(page_name)
    EasyPage.where(["#{EasyPage.table_name}.page_name LIKE ?", "#{page_name}-%"])
  end

  def user_modules(user = nil, entity_id = nil, tab = 1, options = {})
    tab = tab.to_i
    tab = 1 if tab <= 0

    user_tab_modules(tab, user, entity_id, options)
  end

  def built_in?
    self.class.built_in_conditions.each do |condition, value|
      return false unless send(condition) == value
    end

    true
  end

  def user_tab_modules(tab, user = nil, entity_id = nil, options = {})
    scope = EasyPageZoneModule.preload(:zone_definition, :module_definition).joins(:available_zone).readonly(false).order("#{EasyPageAvailableZone.table_name}.position ASC", "#{EasyPageZoneModule.table_name}.position ASC")

    user  = User.find(user) if (!user.nil? && !user.is_a?(User))
    scope = scope.where(user_id: user, entity_id: entity_id, easy_pages_id: self)
    scope = scope.where(tab_id: tab) unless options[:all_tabs]

    all_modules = scope.select { |mod| mod.module_definition&.module_allowed? }

    if options[:without_zones]
      all_modules
    else
      page_modules = self.zones.joins(:zone_definition).pluck(:zone_name).each_with_object({}) { |zone_name, result| result[zone_name] = [] }
      page_modules.merge!(all_modules.group_by { |mod| mod.zone_definition.zone_name })
      page_modules
    end
  end

  def translated_name
    user_defined_name || l("easy_pages.pages.#{page_name.underscore}", default: page_name.underscore.humanize)
  end

  def translated_description
    l("easy_pages.pages_description.#{page_name.underscore}")
  end

  def unassigned_zones
    assigned_zones = self.zones.collect { |zone| zone.easy_page_zones_id }
    assigned_zones ||= []

    scope = EasyPageZone.all
    scope = scope.where("#{EasyPageZone.table_name}.id NOT IN (#{assigned_zones.join(',')})") if assigned_zones.size > 0

    scope.to_a
  end

  def available_modules
    self.modules.select do |m|
      next unless (md = m&.module_definition)
      !Redmine::Plugin.disabled?(md.registered_in_plugin) && !md.deprecated?
    end
  end

  def ensure_available_page_zones
    plz = PAGE_LAYOUTS.detect { |_, p| p[:path] == self.layout_path }
    return true if plz.nil?

    page_layout_zones = plz[1][:zones]

    page_layout_zones.each do |page_layout_zone|
      EasyPageAvailableZone.ensure_easy_page_available_zone self, page_layout_zone
    end

    return true
  end

  def install_registered_modules
    EasyPageModule.install_all_registered_modules_to_page self
  end

  def default_template
    self.templates.where(:is_default => true).first
  end

  # returns true if user is allowed to view the page
  # @param user       [User]           optional user
  # @param permission [Symbol]         optional permission name
  # @param authorized [Boolean, Proc]  optional default returned when strict permissions are disabled
  # @return [Boolean]
  def visible?(user = User.current, permission: nil, authorized: nil)
    return true if user.easy_lesser_admin_for?(:easy_pages_administration)

    if strict_show_permissions?
      permitted_show_principals.where(id: user.group_ids | [user.id]).exists? || permitted_show_easy_user_types.where(id: user.easy_user_type_id).exists?
    elsif !authorized.nil?
      authorized.is_a?(Proc) ? authorized.call : authorized
    else
      user.allowed_to_globally?(:manage_custom_dashboards) || (permission.present? && user.allowed_to_globally?(permission))
    end
  end

  # returns true if user is allowed to edit the page
  # @param user       [User]           optional user
  # @param permission [Symbol]         optional permission name
  # @param authorized [Boolean, Proc]  optional default returned when strict permissions are disabled
  # @return [Boolean]
  def editable?(user = User.current, permission: nil, authorized: nil)
    return true if user.easy_lesser_admin_for?(:easy_pages_administration)

    if strict_permissions?
      permitted_principals.where(id: user.group_ids | [user.id]).exists? || permitted_easy_user_types.where(id: user.easy_user_type_id).exists?
    elsif !authorized.nil?
      authorized.is_a?(Proc) ? authorized.call : authorized
    else
      user.allowed_to_globally?(:manage_custom_dashboards) || (permission.present? && user.allowed_to_globally?(permission))
    end
  end

  private

  class << self
    def built_in_conditions
      { is_user_defined: false, has_template: true, page_scope: nil }
    end
  end

  def change_page_name
    self.page_name = self.page_name.gsub(/[ ]/, '-').dasherize unless self.page_name.nil?
  end

  def journalize_change(*_args)
    return unless @current_journal

    if @current_journal.notes.blank?
      @current_journal.is_system = true
      @current_journal.notes = l(:label_easy_page_permissions_updated)
    end
  end

end
