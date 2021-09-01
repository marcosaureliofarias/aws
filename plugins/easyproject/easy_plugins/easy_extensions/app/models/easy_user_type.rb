class EasyUserType < ActiveRecord::Base
  include Redmine::SafeAttributes

  has_many :users
  has_many :easy_custom_menus, -> { sorted }, :dependent => :destroy
  has_and_belongs_to_many :easy_user_visible_types, :join_table => 'easy_user_types_easy_user_types', :class_name => 'EasyUserType', :foreign_key => 'easy_user_visible_type_id', :association_foreign_key => 'easy_user_type_id'
  has_and_belongs_to_many :easy_user_visible_to_types, :join_table => 'easy_user_types_easy_user_types', :class_name => 'EasyUserType', :foreign_key => 'easy_user_type_id', :association_foreign_key => 'easy_user_visible_type_id'
  has_and_belongs_to_many :easy_queries, :join_table => "#{table_name_prefix}easy_queries_easy_user_types#{table_name_suffix}", :foreign_key => 'easy_user_type_id'

  has_many :visible_users, through: :easy_user_visible_types, class_name: 'User', source: :users

  belongs_to :default_page_template, class_name: 'EasyPageTemplate', foreign_key: 'easy_page_template_id', required: false
  belongs_to :default_role, class_name: 'Role', foreign_key: 'role_id', required: false

  accepts_nested_attributes_for :easy_custom_menus, :allow_destroy => true

  before_save :check_default

  after_update :invalidate_visible_cache
  after_destroy :invalidate_visible_cache

  serialize :settings, Array

  validates :name, :presence => true, :uniqueness => true

  html_fragment :description, :scrub => :strip

  scope :sorted, -> { order("#{table_name}.position ASC") }
  scope :easy_type_internal, -> { where(internal: true) }
  scope :easy_type_external, -> { where(internal: false) }
  scope :easy_type_partner,  -> { where(partner: true) }
  scope :easy_type_regular,  -> { where(partner: false) }

  acts_as_positioned
  acts_as_easy_translate(columns: [:name, :description])

  attr_accessor :is_copy

  safe_attributes 'name', 'settings', 'internal', 'position', 'is_default', 'easy_custom_menus_attributes', 'submenus_attributes', 'reorder_to_position', 'easy_user_visible_type_ids', 'easy_user_visible_to_type_ids', 'show_in_meeting_calendar', 'description', 'is_copy'
  safe_attributes 'easy_page_template_id', 'role_id', 'partner'

  class << self
    def default
      EasyUserType.find_by(is_default: true)
    end

    def available_settings
      { top_menu: top_menu_settings, custom_menu: [] }
    end

    def top_menu_settings
      [:home_icon, :projects, :issues, :more, :custom_menu, :before_search, :search, :jump_to_project, :administration, :sign_out, :user_profile]
    end
  end

  def destroy
    if is_default?
      false
    else
      set_default_before_destroy
      super
    end
  end

  def to_s
    self.name
  end

  def settings=(s)
    s = s.collect { |p| p.to_sym unless p.blank? }.compact.uniq if s
    write_attribute(:settings, s)
  end

  def easy_user_type_for?(setting)
    self.settings.include?(setting.to_sym) ? true : false
  end

  def easy_user_visible_type_ids=(user_types)
    if user_types.is_a?(Array) && user_types.include?('all')
      super(EasyUserType.all.pluck(:id))
    else
      super(user_types)
    end
  end

  def easy_user_visible_to_type_ids=(user_types)
    if user_types.is_a?(Array) && user_types.include?('all')
      super(EasyUserType.all.pluck(:id))
    else
      super(user_types)
    end
  end

  def safe_attributes=(attributes)
    attrs = attributes.respond_to?(:to_unsafe_hash) ? attributes.to_unsafe_hash : attributes

    # Submenu via nested_attributes can be only created
    # Its never updated or destroyed
    easy_custom_menus_attributes = attrs['easy_custom_menus_attributes'] || {}
    easy_custom_menus_attributes.each do |_, menu_attrs|
      submenus_attributes = menu_attrs['submenus_attributes']
      next if submenus_attributes.blank?

      submenus_attributes.each do |_, attrs|
        id = attrs['id']
        next if id.blank?

        if attrs.delete('_destroy').to_s.to_boolean
          EasyCustomMenu.destroy(id)
        else
          EasyCustomMenu.update(id, attrs)
        end
      end

      submenus_attributes.reject! { |_, attrs| attrs['id'].present? }
    end

    super(attrs)

    easy_custom_menus.each do |menu|
      menu.submenus.each do |submenu|
        submenu.easy_user_type = self
      end
    end
  end

  def copy
    copy_easy_user_type = self.dup
    copy_easy_user_type.write_attribute(:name, "(#{l(:label_copied)}) #{ self.read_attribute(:name, translated: false) }")
    copy_custom_menus(copy_easy_user_type)
    copy_easy_user_type.easy_user_visible_types    = self.easy_user_visible_types
    copy_easy_user_type.easy_user_visible_to_types = self.easy_user_visible_to_types
    copy_easy_user_type.is_default = false

    copy_easy_user_type
  end

  def copy_custom_menus(copy_easy_user_type)
    self.easy_custom_menus.each do |ec_menu|
      if ec_menu.root?
        copy_menu = copy_custom_menus_with_easy_translations(ec_menu)

        ec_menu.submenus.each do |submenu|
          copy_menu.submenus << copy_custom_menus_with_easy_translations(submenu)
        end
        copy_easy_user_type.easy_custom_menus << copy_menu
      end
    end
    copy_easy_user_type
  end

  def copy_custom_menus_with_easy_translations(original_entity)
    copy_entity = EasyCustomMenu.new
    copy_entity.attributes = original_entity.attributes.dup.except('root_id', 'id')
    copy_entity = original_entity.copy_translations(copy_entity)
    copy_entity
  end

  private

  def set_default_before_destroy
    Principal.where(:easy_user_type_id => self.id).update_all(:easy_user_type_id => self.class.default.id)
  end

  def check_default
    if self.is_default_changed?
      self.is_default? ? self.class.update_all(:is_default => false) : self.is_default = true
    end
  end

  def invalidate_visible_cache
    EasyUserType.pluck(:id).each do |i|
      Rails.cache.delete "user_visible_#{i}_#{self.id}"
      Rails.cache.delete "user_visible_#{self.id}_#{i}"
    end
  end

end
