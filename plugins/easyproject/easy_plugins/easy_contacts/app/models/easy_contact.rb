# encoding: utf-8
class EasyContact < ActiveRecord::Base
  include Redmine::SafeAttributes
  include Redmine::NestedSet::IssueNestedSet

  CONTACT_FORMATS = {
      :firstname_lastname => {
          :string => '#{firstname} #{lastname}',
          :order => %w(firstname lastname id),
          :setting_order => 1
      },
      :firstname_lastinitial => {
          :string => '#{firstname} #{lastname.to_s.chars.first}.',
          :order => %w(firstname lastname id),
          :setting_order => 2
      },
      :firstinitial_lastname => {
          :string => '#{firstname.to_s.gsub(/(([[:alpha:]])[[:alpha:]]*\.?)/, \'\2.\')} #{lastname}',
          :order => %w(firstname lastname id),
          :setting_order => 2
      },
      :firstname => {
          :string => '#{firstname}',
          :order => %w(firstname id),
          :setting_order => 3
      },
      :lastname_firstname => {
          :string => '#{lastname} #{firstname}',
          :order => %w(lastname firstname id),
          :setting_order => 4
      },
      :lastname_coma_firstname => {
          :string => '#{lastname}, #{firstname}',
          :order => %w(lastname firstname id),
          :setting_order => 5
      },
      :lastname => {
          :string => '#{lastname}',
          :order => %w(lastname id),
          :setting_order => 6
      }
  }

  CF_ATTR_NAMES = ['title', 'organization', 'email', 'telephone', 'street', 'city', 'region', 'postal_code', 'country', 'registration_no', 'vat_no', 'bank_account', 'swift', 'iban', 'bic', 'variable_symbol']

  SPECIAL_VISIBILITY_FIELD_NAMES = %w(author_id updated_on firstname lastname assigned_to_id external_assigned_to_id parent_id created_on)

  attr_reader :principal_assignement, :project_assignement

  safe_attributes 'assigned_to_id', 'external_assigned_to_id', if: lambda {|easy_contact, user| easy_contact.new_record? || easy_contact.editable?(user)}
  safe_attributes *%w{ firstname lastname custom_field_values author_note is_global is_public private custom_fields type_id easy_contact_type_id easy_contact_group_ids tag_list parent_id easy_avatar_url easy_external_id }
  safe_attributes :notes, :if => lambda { |easy_contact, user| easy_contact.commentable?(user) && !easy_contact.new_record? }

  belongs_to :easy_contact_type, :class_name => 'EasyContactType', :foreign_key => 'type_id'
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'

  has_and_belongs_to_many :easy_contact_groups, :class_name => 'EasyContactGroup',
                          :join_table => 'easy_contacts_group_assignments',
                          :foreign_key => 'contact_id',
                          :association_foreign_key => 'group_id',
                          :order => "#{EasyContactGroup.table_name}.group_name DESC"

  has_and_belongs_to_many :references_by, :class_name => 'EasyContact', :join_table => 'easy_contacts_references', :foreign_key => 'referenced_by', :association_foreign_key => 'referenced_to'
  has_and_belongs_to_many :references_to, :class_name => 'EasyContact', :join_table => 'easy_contacts_references', :foreign_key => 'referenced_to', :association_foreign_key => 'referenced_by'


  # --- Backward compatibility (contact types) --------------------------------

  has_and_belongs_to_many :references_by_personals, -> { includes(:easy_contact_type).where(:easy_contact_type => { :internal_name => 'personal' }) }, :class_name => 'EasyContact', :join_table => 'easy_contacts_references', :foreign_key => 'referenced_by', :association_foreign_key => 'referenced_to'
  has_and_belongs_to_many :references_by_corporates, -> { includes(:easy_contact_type).where(:easy_contact_type => { :internal_name => 'corporate' }) }, :class_name => 'EasyContact', :join_table => 'easy_contacts_references', :foreign_key => 'referenced_by', :association_foreign_key => 'referenced_to'
  has_and_belongs_to_many :references_by_accounts, -> { includes(:easy_contact_type).where(:easy_contact_type => { :internal_name => 'account' }) }, :class_name => 'EasyContact', :join_table => 'easy_contacts_references', :foreign_key => 'referenced_by', :association_foreign_key => 'referenced_to'

  # --- End backward compatibility (contact types) ----------------------------

  has_many :easy_contact_entity_assignments, :dependent => :destroy

  has_many :projects, lambda { where(:easy_contact_entity_assignments => { :entity_type => 'Project' }).order("#{Project.table_name}.name DESC") }, :through => :easy_contact_entity_assignments, :as => :entity
  has_many :users, lambda { where(:easy_contact_entity_assignments => { :entity_type => 'Principal' }) }, :through => :easy_contact_entity_assignments, :as => :entity

  has_many :issues, lambda { where(:easy_contact_entity_assignments => { :entity_type => 'Issue' }) }, :through => :easy_contact_entity_assignments, :as => :entity

  has_one :easy_avatar, :class_name => 'EasyAvatar', :as => :entity, :dependent => :destroy
  has_many :easy_entity_activities, :as => :entity, :dependent => :destroy

  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'
  belongs_to :external_assigned_to, :class_name => 'User', :foreign_key => 'external_assigned_to_id'

  scope :visible, lambda { |*args|
    where(EasyContact.visible_condition(args.first))
  }

  scope :like, lambda { |q|
    q = q.to_s
    if q.blank?
      where({})
    else
      sql = []
      p = {}
      tokens = q.split(/\s/)
      tokens.each_with_index do |t, i|
        dbi = "token_#{i}".to_sym
        p[dbi] = "%#{t}%"
        sql << "(#{Redmine::Database.like("#{table_name}.firstname", ":#{dbi}")} OR #{Redmine::Database.like("#{table_name}.lastname", ":#{dbi}")})"
      end
      where(sql.join(' AND '), p)
    end
  }

  scope :global, lambda { where(:is_global => true) }
  scope :sorted, lambda { order(*EasyContact.fields_for_order_statement) }
  scope :partner, lambda { where(type_id: EasyContact.partner_type_id) } # don't remove

  html_fragment :author_note, :scrub => :strip

  attr_accessor :next_contact_reference_id
  attr_writer :additional_custom_fields
  attr_accessor :project
  attr_accessor :skip_name_validation
  attr_accessor :current_journal

  acts_as_taggable_on :tags, :plugin_name => :easy_contacts
  acts_as_customizable
  acts_as_attachable
  acts_as_searchable :columns => ["#{self.table_name}.fullname", "#{self.table_name}.author_note"],
                     :preload => [:easy_contact_entity_assignments, :attachments, :easy_contact_type],
                     :scope => lambda { |options| self.includes(:easy_contact_entity_assignments) },
                     :project_key => "#{EasyContactEntityAssignment.table_name}.entity_type='Project' AND #{EasyContactEntityAssignment.table_name}.entity_id"
  searchable_options[:title_columns] = ["#{self.table_name}.fullname"]

  acts_as_event :title => :name,
                :description => :author_note,
                :url => Proc.new { |o| { :controller => 'easy_contacts', :action => 'show', :id => o.id } },
                :datetime => :updated_on,
                :type => 'easy_contact'

  acts_as_easy_journalized \
    non_journalized_columns: ['author_note', 'latitude', 'longitude'],
    format_detail_boolean_columns: ['is_public', 'non_editable', 'private'],
    format_detail_reflection_columns: ['external_assigned_to_id'],
    features: ['refresh_updated_at']

  set_associated_query_class EasyContactQuery
  acts_as_easy_entity_replacable_tokens easy_query_class: EasyContactQuery

  validates :type, :presence => true
  validates :lastname, :firstname, :presence => true, :if => Proc.new { |contact| !skip_name_validation && contact.easy_contact_type && contact.person? }
  validates :firstname, :lastname, :length => { maximum: 255 }
  validate :validate_parent, if: -> { parent_id.present? }
  validates :guid, uniqueness: true

  before_validation :default_values
  before_validation :set_guid
  before_save :check_author_note
  before_save -> { self.fullname = self.to_s }
  after_save :references_mirror
  after_save :create_journal

  after_commit -> { GetContactGeocodeJob.perform_later(self.id) }, on: [:create, :update], if: -> { address.present? && address_changed? }

  delegate :notes, :notes=, :to => :current_journal, :allow_nil => true

  def self.visible_condition(user=nil)
    user ||= User.current
    t = EasyContact.table_name
    conditions = "(#{t}.private = #{EasyContact.connection.quoted_false} OR #{t}.author_id = #{user.id})"
    return conditions if user.admin?

    contact_type_ids = user.easy_user_type&.easy_contact_type_ids
    return '1=0' unless contact_type_ids.present?
    conditions << " AND #{t}.type_id IN (#{contact_type_ids.join(',')})"

    role_conditions = []
    user.allowed_to?(:view_easy_contacts, nil, {global: true}) do |role, user|
      case role.easy_contacts_visibility
      when 'all'
        role_conditions << '1=1'
      when 'own'
        role_conditions << "(#{t}.author_id = #{user.id} OR #{t}.assigned_to_id = #{user.id} OR #{t}.external_assigned_to_id = #{user.id})"
      when 'author'
        role_conditions << "#{t}.author_id = #{user.id}"
      when 'assigned'
        role_conditions << "#{t}.assigned_to_id = #{user.id} OR #{t}.external_assigned_to_id = #{user.id}"
      end
      false
    end

    if role_conditions.any?
      conditions << " AND (#{role_conditions.join(' OR ')})"
    else
      conditions = '1=0'
    end
    conditions
  end

  def visible?(user = nil)
    user ||= User.current

    return false unless user.visible_contact_via_user_type(self)

    user.allowed_to?(:view_easy_contacts, nil, {global: true}) do |role, user|
      case role.easy_contacts_visibility
      when 'all'
        true
      when 'own'
        [self.assigned_to, self.external_assigned_to, self.author].include?(user)
      when 'author'
        self.author == user
      when 'assigned'
        [self.assigned_to, self.external_assigned_to].include?(user)
      else
        false
      end
    end
  end

  def editable?(user = nil)
    user ||= User.current
    user.allowed_to_globally?(:manage_easy_contacts, {}) ||
        (user.allowed_to_globally?(:manage_author_easy_contacts, {}) && user.id == self.author_id) ||
        (user.allowed_to_globally?(:manage_assigned_easy_contacts, {}) && [self.assigned_to_id, self.external_assigned_to_id].include?(user.id))
  end

  def deletable?(user = nil)
    user ||= User.current
    user.allowed_to_globally?(:delete_easy_contacts, {}) ||
        (user.allowed_to_globally?(:delete_author_easy_contacts, {}) && user.id == self.author_id) ||
        (user.allowed_to_globally?(:delete_assigned_easy_contacts, {}) && [self.assigned_to_id, self.external_assigned_to_id].include?(user.id))
  end

  def self.fields_for_order_statement(table=nil)
    table ||= table_name
    columns = ['type_id'] + (EasyContact.name_formatter[:order] - ['id']) + ['lastname', 'id']
    columns.uniq.map { |field| "#{table}.#{field}" }
  end

  def self.name_formatter(formatter = nil)
    CONTACT_FORMATS[formatter || EasySetting.value('easy_contact_format_name')] || CONTACT_FORMATS[:firstname_lastname]
  end

  def self.easy_merge_easy_contacts(easy_contacts, easy_contact_merge_to)
    return false if easy_contacts.count <= 1 && easy_contacts.first == easy_contact_merge_to

    easy_contacts = easy_contacts - [easy_contact_merge_to]
    merged = true
    updated_author_note = easy_contact_merge_to.author_note.to_s.dup

    easy_contacts.each do |easy_contact|
      if !easy_contact.easy_merge_to(easy_contact_merge_to)
        merged = false
      end
      Mailer.with_deliveries(false) do
        easy_contact.init_system_journal(User.current, I18n.t(:label_merged_into, id: "#{easy_contact_merge_to.name}")).save
      end
      updated_author_note << easy_merge_entity_description(easy_contact)
    end

    begin
      easy_contact_merge_to.author_note = updated_author_note
      Mailer.with_deliveries(false) do
        easy_contact_merge_to.save
      end
    rescue ActiveRecord::StaleObjectError
      # if it is parent, it is changed during merging
      easy_contact_merge_to.reload
      easy_contact_merge_to.author_note = updated_author_note
      easy_contact_merge_to.save
    end

    easy_contacts_in_notes = easy_contacts.map(&:name).join(', ')
    easy_contact_merge_to.init_system_journal(User.current, I18n.t(:label_merged_from, :ids => "#{easy_contacts_in_notes}")).save

    merged
  end

  # don't remove
  def self.partner_type_id
    EasySetting.value(:easy_contacts_partner_type_id)
  end

  def easy_merge_to(entity_to_merge)
    entity_to_merge_class = entity_to_merge.class
    #
    # selected entities to copy
    # for example: related entities is not necessary to copy
    #
    entity_types_to_copy = Set['Journal', 'Attachment', 'EasyContactEntityAssignment']

    associations_to_merge = entity_to_merge_class.reflections.collect { |assoc| assoc[0].to_sym } # get all associations

    # merge custom values
    custom_values.each do |v|
      easy_merge_custom_value(entity_to_merge, v)
    end
    Mailer.with_deliveries(false) do
      entity_to_merge.save
    end

    associations_to_merge -= [:custom_values]
    associations_to_merge.each do |association|
      assoc = association.to_s
      reflection = entity_to_merge_class.reflections[assoc]

      case reflection.macro
      when :has_and_belongs_to_many, :has_many
        entities = self.send(assoc)
        next if entities.blank?

        entities.each do |r|
          duplicate = easy_duplicate_entity_for_merge(r, entity_types_to_copy)
          begin
            Mailer.with_deliveries(false) do
              # check if object does not already contain duplicate in its associtation
              # if Duplicate Entry exception is raised, then object with association cannot be saved
              if entity_types_to_copy.include?(r.class.name) || !entity_to_merge.send(assoc).include?(duplicate)
                entity_to_merge.send(assoc) << duplicate
              end
            end
          rescue StandardError => e
            # association already contains duplicate object
            # read only associations
          end
        end
      end
    end

    self.reload
    Mailer.with_deliveries(false) do
      self.save
    end
  end

  def validate_parent
    errors.add(:parent, :invalid) if !parent_id.nil? && saved_change_to_parent_id? && self_and_descendants.exists?(parent_id)
  end

  def easy_duplicate_entity_for_merge(original, entity_types_to_copy)
    duplicate = original
    if entity_types_to_copy.include?(original.class.name)
      begin
        duplicate = original.dup
      rescue StandardError => e
        # cannot duplicate object, use original instead
      end
    end
    duplicate
  end

  def self.easy_merge_entity_description(merging_entity)
    "\r\n" << '-' * 60 << ' ' << I18n.t(:label_merged_from, :ids => "#{merging_entity.name}") << "\r\n" << merging_entity.author_note.to_s
  end

  def easy_merge_custom_value(original_easy_contact, custom_value_to_merge)
    case custom_value_to_merge.custom_field.format
    when EasyExtensions::FieldFormats::Email, Redmine::FieldFormat::StringFormat, Redmine::FieldFormat::TextFormat
      easy_merge_text_custom_value(original_easy_contact, custom_value_to_merge, ',')
    end
  end

  def easy_merge_text_custom_value(original_easy_contact, custom_value_to_merge, separator = nil)
    original_cv = original_easy_contact.custom_value_for(custom_value_to_merge.custom_field_id)
    if (original_cv)
      if separator
        new_value = (original_cv.value.to_s.split(separator) + custom_value_to_merge.value.to_s.split(separator)).uniq.join(separator)
      else
        new_value = original_cv.value.to_s + custom_value_to_merge.value.to_s
      end

      original_easy_contact.custom_field_values = { custom_value_to_merge.custom_field.id.to_s => new_value.to_s }
    else
      original_easy_contact.custom_field_values = { custom_value_to_merge.custom_field.id.to_s => custom_value_to_merge.value.to_s }
    end
  end

  def set_guid
    self.guid = EasyUtils::UUID.generate if self.guid.blank?
  end

  def etag
    '%s-%d' % [self.guid, self.updated_on.to_i]
  end

  def name(formatter = nil)
    if field_enabled?('lastname')
      f = self.class.name_formatter(formatter)
      if formatter
        eval('"' + f[:string] + '"')
      else
        @name ||= eval('"' + f[:string] + '"')
      end
    else
      if easy_contact_type && person?
        [firstname.presence, lastname.presence].compact.join(" ")
      else
        firstname.to_s
      end
    end
  end

  alias_method :contact_name, :name
  alias_method :to_s, :name

  def easy_contacts
    (references_by + references_to).uniq
  end

  def easy_contacts=(collection)
    return if collection.nil?
    self.references_by = collection.reject{|contact| contact == self}
    self.references_to = collection.reject{|contact| contact == self}
  end

  def street
    custom_field_value(EasyContacts::CustomFields.street_id)
  end

  def city
    custom_field_value(EasyContacts::CustomFields.city_id)
  end

  def state
    nil
  end

  def country
    custom_field_value(EasyContacts::CustomFields.country_id)
  end

  def address
    [street, city, state, country].reject(&:blank?).join(', ')
  end

  def custom_field_values=(values)
    if new_record?
      @address_changed = true
      return super(values)
    end

    address_was = address
    ret = super(values)
    @address_changed = true if address != address_was
    ret
  end

  def address_changed?
    @address_changed
  end

  def coordinates
    [latitude, longitude].reject(&:blank?).join(', ')
  end

  def disabled_core_fields
    easy_contact_type ? easy_contact_type.disabled_core_fields : []
  end

  def field_enabled?(field)
    !disabled_core_fields.include?(field)
  end

  def additional_custom_fields
    @additional_custom_fields || []
  end

  # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
  def available_custom_fields
    RequestStore.store['easy_contact_custom_fields_by_type'] ||= {}
    RequestStore.store['easy_contact_custom_fields_by_type'][self.type_id] ||= self.easy_contact_type ? self.easy_contact_type.custom_fields.sorted.to_a : []
  end

  def available_custom_fields_scope
    easy_contact_type ? easy_contact_type.custom_fields.visible.sorted : CustomField.none
  end

  alias :base_reload :reload
  def reload(*args)
    RequestStore.store['easy_contact_custom_fields_by_type'] = nil
    @visible_custom_field_values = nil
    @visible_custom_field_values_without_empty_primary = nil
    @project_assignement = nil
    @principal_assignement = nil
    @address_changed = nil
    base_reload(*args)
  end

  def editable_custom_field_values(user = nil)
    visible_custom_field_values
  end

  def visible_custom_field_values
    @visible_custom_field_values ||= begin
      super.select do |c|
        (c.custom_field.is_primary? || c.value.present? || (!new_record? && c.custom_field.show_empty?)) && c.custom_field.visible_by?(nil, User.current)
      end
    end
  end

  def visible_custom_field_values_without_empty_primary
    @visible_custom_field_values_without_empty_primary ||= visible_custom_field_values.reject { |c| c.custom_field.is_primary? && c.value.blank? && !c.custom_field.show_empty? }
  end

  def unused_non_primary_custom_fields
    cf_ids = visible_custom_field_values.collect(&:custom_field_id)
    self.available_custom_fields.select do |c|
      (new_record? && !c.is_primary?) || (!new_record? && !cf_ids.include?(c.id))
    end
  end

  def add_non_primary_custom_fields(custom_fields)
    custom_fields = custom_fields.dup
    self.additional_custom_fields = []
    unless custom_fields.blank?
      available_custom_fields.each do |custom_field|
        custom_fields.delete custom_field.id.to_s
      end

      custom_fields.each do |custom_field_id|
        self.additional_custom_fields << EasyContactCustomField.find(custom_field_id[0])
      end
    end
  end

  def attachments_visible?(user=User.current)
    true
  end

  def attachments_editable?(user=nil)
    editable?(user)
  end

  def attachments_deletable?(user=User.current)
    true
  end

  def allowed_groups
    return @allowed_groups if @allowed_groups
    @allowed_groups = EasyContactGroup.all

    return @allowed_groups
  end

  # TODO: Rozpracovana myslenka do budoucna.... Dostat sem projekt a zobrazovat jen skupiny daneho projektu pokud je user na kontextu projektu.
  def contact_groups
    if self.project
      self.easy_contact_groups.select_if { |i| i.entity_type == 'Project' && i.entity_id = self.project.id }.join(', ')
    else
      self.easy_contact_groups.join(', ')
    end
  end

  def type
    easy_contact_type
  end

  def sales_activities
    easy_entity_activities.sorted
  end


  # --- Backward compatibility (contact types) --------------------------------

  def person?
    self.easy_contact_type.personal?
  end

  def company?
    self.easy_contact_type.corporate?
  end

  def account?
    self.easy_contact_type.account?
  end

  def css_classes(user = nil, options = {})
    # "easy-contact #{easy_contact_type.icon_path}"

    user ||= User.current
    css = 'easy-contact'
    if self.person?
      css << ' person'
    elsif self.company?
      css << ' company'
    elsif self.account?
      css << ' account'
    end
    if user.logged?
      css << ' assigned-to-me' if self.assigned_to_id == user.id
      if EasyUserType.easy_type_partner.any?
        css << ' external-assigned-to-me' if self.external_assigned_to_id == user.id
      end
    end

    css
  end

  # --- End backward compatibility (contact types) ----------------------------

  def self.css_icon
    'icon icon-group'
  end

  def css_icon
    self.easy_contact_type.css_icon
  end

  def commentable?(user=User.current)
    return @commentable unless @commentable.nil?
    @commentable = user.allowed_to_globally?(:add_note_easy_contacts, {})
    @commentable
  end

  CF_ATTR_NAMES.each do |att_name|
    define_method("cf_#{att_name}_value") do
      i = instance_variable_get(:"@cf_#{att_name}_value")
      if i.nil?
        i = instance_variable_set(:"@cf_#{att_name}_value", self.find_cf(EasyContacts::CustomFields.send("#{att_name}_id")))
      end

      return i
    end

    define_method("cf_#{att_name}_value=") do |value|
      self.custom_field_values = { EasyContacts::CustomFields.send("#{att_name}_id").to_s => value }
      instance_variable_set(:"@cf_#{att_name}_value", value)
    end
  end

  def find_cf(id)
    self.custom_field_values.detect { |i| i.custom_field_id == id }.try(:value)
  end

  def eu_member?
    ISO3166::Country[cf_country_value].try(:in_eu?)
  end

  def global?
    is_global?
  end

  def is_private?
    private?
  end

  def assignable_users
    User.active.non_system_flag.sorted.easy_type_regular
  end

  def external_assignable_users
    User.active.non_system_flag.sorted.easy_type_partner
  end

  SPECIAL_VISIBILITY_FIELD_NAMES.each do |method|
    self.class.send :define_method, "#{method}_field_visible?" do
      EasyContacts::FieldsSettings.new(self, method).visible?
    end
  end

  def anonymize!
    self.custom_values.where(custom_field_id: anonymized_custom_fields).delete_all
    self.journals = []
    self.lastname = l(:field_easy_contact)
    self.firstname = l(:field_anonymized)
    self.save(validate: false)
  end

  def anonymized_custom_fields
    EasyContactCustomField.where(clear_when_anonymize: true)
  end

  def type_id=(type_id)
    if type_id.to_s != self.type_id.to_s
      self.type = type_id.present? ? EasyContactType.find_by(id: type_id) : nil
    end

    self.type_id
  end
  alias_method :easy_contact_type_id=, :type_id=

  def type=(type)
    type_was = self.type
    association(:easy_contact_type).writer(type)
    if type != type_was
      reassign_custom_field_values
    end

    self.type
  end
  alias_method :easy_contact_type=, :type=

  def safe_attributes=(attrs, user=User.current)
    if attrs.respond_to?(:to_unsafe_hash)
      attrs = attrs.to_unsafe_hash
    end
    return unless attrs.is_a?(Hash)

    if (type_id = attrs.delete('type_id')) && safe_attribute?('type_id')
      self.type_id = type_id
    elsif (type_id = attrs.delete('easy_contact_type_id')) && safe_attribute?('easy_contact_type_id')
      self.easy_contact_type_id = type_id
    end

    self.attributes = delete_unsafe_attributes(attrs, user)
  end

  def self.get_emails(easy_contacts)
    return [] unless easy_contacts.present?

    values = CustomValue.includes(:custom_field).
      where(custom_fields: {field_format: :email}).
      where(customized_id: easy_contacts.map(&:id)).
      where.not(value: [nil, '']).order(:value).pluck(:value)

    values.inject([]) do |emails, value|
      emails.concat(value.scan(EasyExtensions::Mailer::EMAIL_REGEXP))
      emails
    end.sort.uniq
  end

  # don't remove
  def partner?
    self.type_id == EasySetting.value(:easy_contacts_partner_type_id).to_i
  end

  private

  def after_destroy
    self.references_by.each do |refc|
      refc.references_by.delete_if { |c| c.id == self.id }
      refc.save
    end
  end

  def check_author_note
    unless self.author_note.blank?
      self.author_note = nil if Sanitize.clean(self.author_note).strip.sub(/\302\240/, '').blank?
    end
  end

  def references_mirror
    references_to.delete_all
    references_by.each do |r|
      begin
        r.references_by << self
      rescue ActiveRecord::RecordNotUnique
      end
    end
    references_to.reload
  end

  def default_values
    self.author_id ||= User.current.id
    self.type_id ||= EasyContactType.default.try(:id)
  end

end
