class EasyContactType < ActiveRecord::Base
  self.table_name = 'easy_contact_type'
  include Redmine::SafeAttributes

  safe_attributes 'firstname', 'lastname', 'position', 'core_fields', 'is_default', 'reorder_to_position', 'icon_path', 'internal_name', 'type_name', 'custom_field_ids'

  # Keep ordering !!!
  CORE_FIELDS = ['firstname', 'lastname']
  # CORE_FIELDS_UNDISABLABLE = []
  # CORE_FIELDS_ALL = (CORE_FIELDS_UNDISABLABLE + CORE_FIELDS).freeze

  has_many :contacts, :class_name => "EasyContact", :foreign_key => 'type_id'
  has_and_belongs_to_many :custom_fields, :class_name => 'EasyContactCustomField', :join_table => "#{table_name_prefix}custom_fields_easy_contact_type#{table_name_suffix}", :association_foreign_key => 'custom_field_id', :foreign_key => 'easy_contact_type_id'
  has_and_belongs_to_many :easy_user_types, join_table: 'easy_contact_types_easy_user_types'

  before_save :ensure_default
  after_save :invalidate_cache
  after_destroy :invalidate_cache

  scope :sorted, lambda { order("#{table_name}.position ASC") }

  acts_as_positioned

  def self.default
    RequestStore.store[:default_contact_type] ||= EasyContactType.where(:is_default => true).first || EasyContactType.first
  end

  def self.invalidate_cache
    RequestStore.store[:default_contact_type] = nil
  end

  def name
    type_name
  end

  def to_s
    name
  end

  def ensure_default
    if is_default? && is_default_changed?
      EasyContactType.update_all(:is_default => false)
    end
  end

  def invalidate_cache
    self.class.invalidate_cache
  end

  def disabled_core_fields
    return @disabled_core_fields if @disabled_core_fields

    i = -1
    _fields_bits = fields_bits || 0
    @disabled_core_fields = CORE_FIELDS.select { i += 1; _fields_bits & (2 ** i) != 0 }
  end

  def core_fields
    CORE_FIELDS - disabled_core_fields
  end

  def core_fields=(fields)
    raise ArgumentError, 'Core_fields takes an array' unless fields.is_a?(Array)

    bits = 0
    CORE_FIELDS.each_with_index do |field, i|
      unless fields.include?(field)
        bits |= 2 ** i
      end
    end
    self.fields_bits = bits
    @disabled_core_fields = nil
    core_fields
  end

  def move_easy_contacts(other_type, custom_fields_map=nil)
    custom_fields_map ||= {}
    custom_fields_map = Hash[custom_fields_map.map{|k, v| [k.to_i, v.to_i]}]

    Mailer.with_deliveries(false) do
      transaction do
        contacts.preload(:custom_values).find_each(batch_size: 50) do |contact|

          contact.custom_values.each do |cv|
            mapped_to = custom_fields_map[cv.custom_field_id]

            if !mapped_to.nil? && mapped_to > 0
              cv.custom_field_id = mapped_to
              cv.save
            else
              cv.destroy
            end
          end

        end

        contacts.update_all(type_id: other_type.id)
      end
    end
  end

  def custom_field_mapping_data(other_type)
    return {} if other_type.blank?

    data = {}
    custom_fields.each do |cf_from|
      data[cf_from] = other_type.custom_fields.select { |cf_to| cf_from.field_format == cf_to.field_format }
    end
    data
  end

  def css_icon
    if icon_path
      "icon #{icon_path}"
    else
      ''
    end
  end


  # --- Backward compatibility (contact types) --------------------------------

  def self.personal
    where(:internal_name => 'personal').first
  end

  def self.corporate
    where(:internal_name => 'corporate').first
  end

  def self.account
    where(:internal_name => 'account').first
  end

  def self.css_personal_icon
    'icon icon-user'
  end

  def self.css_corporate_icon
    'icon icon-home'
  end

  def self.css_account_icon
    'icon icon-server-authentication'
  end

  # def css_icon
  #   if self.personal?
  #     self.class.css_personal_icon
  #   elsif self.corporate?
  #     self.class.css_corporate_icon
  #   elsif self.account?
  #     self.class.css_account_icon
  #   else
  #     ''
  #   end
  # end

  # def name
  #   return I18n.t(:corporate, :scope => [:easy_contact_types]) if self.corporate?
  #   return I18n.t(:personal, :scope => [:easy_contact_types]) if self.personal?
  #   return I18n.t(:account, :scope => [:easy_contact_types]) if self.account?
  #
  #   type_name
  # end

  def personal?
    return self.internal_name == 'personal'
  end

  def corporate?
    return self.internal_name == 'corporate'
  end

  def account?
    return self.internal_name == 'account'
  end

  # --- End backward compatibility (contact types) ----------------------------

end
