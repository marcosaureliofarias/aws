require 'easy_crm/easy_mail_template_easy_crm_case'

class EasyCrmCase < ActiveRecord::Base
  include Redmine::SafeAttributes
  include EasyExtensions::EasyMailTemplateTokens

  belongs_to :easy_crm_case_status
  belongs_to :project
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'
  belongs_to :external_assigned_to, :class_name => 'User', :foreign_key => 'external_assigned_to_id'
  belongs_to :easy_closed_by, :class_name => 'User'
  belongs_to :easy_last_updated_by, :class_name => 'User'
  belongs_to :main_easy_contact, class_name: 'EasyContact', required: false

  has_and_belongs_to_many :issues, :after_add => :issue_related_contact

  has_many :easy_entity_assigned, :class_name => 'EasyEntityAssignment', :as => :entity_to, :dependent => :delete_all
  has_many :related_entities, :class_name => 'EasyEntityAssignment', :as => :entity_from, :dependent => :delete_all
  has_many :related_projects, :through => :related_entities, :source => :entity_to, :source_type => 'Project'
  has_many :easy_crm_case_items, lambda { sorted }, :dependent => :destroy, inverse_of: :easy_crm_case
  has_many :easy_contact_entity_assignments, :as => :entity, :dependent => :destroy
  has_many :easy_contacts, :through => :easy_contact_entity_assignments


  # --- Backward compatibility (contact types) --------------------------------

  has_many :easy_contacts_personals, lambda {  joins(:easy_contact_type).where(:easy_contact_type => {:internal_name => 'personal'}) }, :through => :easy_contact_entity_assignments, :source => :easy_contact
  has_many :easy_contacts_corporates, lambda {  joins(:easy_contact_type).where(:easy_contact_type => {:internal_name => 'corporate'}) }, :through => :easy_contact_entity_assignments, :source => :easy_contact
  has_many :easy_contacts_accounts, lambda {  joins(:easy_contact_type).where(:easy_contact_type => {:internal_name => 'account'}) }, :through => :easy_contact_entity_assignments, :source => :easy_contact
  has_many :time_entries, :as => :entity, :dependent => :destroy
  has_many :easy_entity_activities, :as => :entity, :dependent => :destroy

  # --- End backward compatibility (contact types) ----------------------------


  scope :visible, lambda { |*args|
    joins(:project).
    where(visible_condition(args.shift || User.current, *args))
  }

  scope :like, lambda {|*args| where(EasyCrmCase.send(:search_tokens_condition, ["#{table_name}.name", "#{table_name}.id"], args.reject(&:blank?), false))}

  scope :active, lambda{where(:is_canceled => false, :is_finished => false)}
  scope :searchable, -> { EasyCrmCaseStatus.where(show_in_search_results: true).exists? ? visible.joins(:easy_crm_case_status).where(easy_crm_case_statuses: { show_in_search_results: true }) : visible }

  scope :is_paid, -> { includes(:easy_crm_case_status).where(easy_crm_case_statuses: { is_paid: true }) }

  validates :project_id, :presence => true
  validates :name, :presence => true, :length => 0..255
  validates :telephone, :length => { maximum: 255 }
  validates :author_id, :presence => true
  validates :easy_crm_case_status_id, :presence => true
  validates :price, :allow_blank => true, :numericality => true
  validates :probability, :allow_blank => true, :numericality => true
  validates :main_easy_contact_id, presence: true, if: Proc.new { |crm| crm.easy_crm_case_status.try(:is_easy_contact_required?) }
  validate :validate_required_fields
  validate :validate_status_only_for_admin

  accepts_nested_attributes_for :easy_crm_case_items, :allow_destroy => true, :reject_if => proc{|attributes| attributes['name'].blank?}

  acts_as_taggable_on :tags, :plugin_name => :easy_crm
  acts_as_customizable
  acts_as_attachable :after_add => :attachment_added, :after_remove => :attachment_removed
  acts_as_searchable :columns => ["#{self.table_name}.name", "#{self.table_name}.description", "#{self.table_name}.email", "#{self.table_name}.telephone"],
                     :preload => [:easy_crm_case_status, :assigned_to, :external_assigned_to],
                     :date_column => :created_at,
                     :scope => (lambda do |options|
                       if options[:params] && options[:params][:easy_crm_case] && options[:params][:easy_crm_case][:all] == '1'
                         visible
                       else
                         searchable
                       end
                     end)
  acts_as_event :title => Proc.new {|o| "#{l(:project_module_easy_crm)} - #{o.name}"},
    :url => Proc.new {|o| {:controller => 'easy_crm_cases', :action => 'show', :id => o, :project_id => o.project}},
    :datetime => :created_at
  acts_as_activity_provider :permission => :view_easy_crms, :author_key => :author_id, :timestamp => "#{EasyCrmCase.table_name}.created_at", :scope => joins(:project)
  # set scope default activities(sidebar)
  # easy_activity_options[:type][:user_scope] => Proc.new { |user, scope| scope.where ... }
  # :type => 'issues' .. determines for which type the options is, Journal is for multiple types
  self.activity_provider_options[:easy_activity_options] = {
    easy_event_type_name => {
      :user_scope => Proc.new { |user, scope| scope.joins("LEFT JOIN #{Watcher.table_name} ON #{Watcher.table_name}.watchable_type='EasyCrmCase' AND #{Watcher.table_name}.watchable_id=#{EasyCrmCase.table_name}.id").where("#{Watcher.table_name}.user_id = :u OR #{EasyCrmCase.table_name}.author_id = :u OR #{EasyCrmCase.table_name}.assigned_to_id = :u OR #{EasyCrmCase.table_name}.external_assigned_to_id = :u", u: user.id) }
    }
  }
  self.activity_provider_options[:update_timestamp] = "#{table_name}.updated_at"
  acts_as_easy_journalized format_detail_date_columns: ['next_action', 'contract_date'],
    format_detail_boolean_columns: ['need_reaction', 'is_canceled', 'is_finished'],
    format_detail_reflection_columns: ['easy_crm_case_status_id', 'external_assigned_to_id'],
    non_journalized_columns: ['easy_last_updated_by_id', 'all_day']
  acts_as_easy_entity_replacable_tokens :easy_query_class => EasyCrmCaseQuery
  acts_as_watchable

  before_save :set_total_price

  acts_as_easy_currency(:price, :currency, :date_for_price_recalculation)

  set_associated_query_class EasyCrmCaseQuery

  acts_as_user_readable

  html_fragment :description, :scrub => :strip

  attr_reader :current_journal
  delegate :notes, :notes=, :private_notes, :private_notes=, :to => :current_journal, :allow_nil => true
  alias_attribute :created_on, :created_at
  alias_attribute :updated_on, :updated_at

  attr_accessor :send_to_external_mails

  safe_attributes 'name', 'description', 'author_id', 'assigned_to_id', 'external_assigned_to_id', 'easy_crm_case_status_id',
    'contract_date', 'email', 'email_cc', 'telephone', 'custom_field_values', 'custom_fields',
    'send_to_external_mails', 'need_reaction', 'next_action', 'all_day', 'is_canceled', 'is_finished',
    'easy_contact_ids', 'project_id', 'easy_crm_case_items_attributes', 'currency', 'tag_list',
    'lead_value', 'probability', 'main_easy_contact_id', 'easy_external_id', 'lock_version',
    if: lambda { |easy_crm_case, user| easy_crm_case.new_record? || easy_crm_case.editable?(user) }
  safe_attributes 'watcher_user_ids', 'watcher_group_ids',
    if: lambda { |easy_crm_case, user| user.allowed_to?(:add_easy_crm_case_watchers, easy_crm_case.project) }

  safe_attributes 'notes', if: lambda { |easy_crm_case, user| easy_crm_case.editable?(user)}

  safe_attributes 'price', if: lambda { |easy_crm_case, _user| !EasySetting.value('easy_crm_use_items', easy_crm_case.project) }

  easy_mail_template_token 'crm_case_id', Proc.new{|crm_case| '#' + crm_case.id.to_s}
  easy_mail_template_token 'crm_case_name',  Proc.new{|crm_case| crm_case.name.to_s}
  easy_mail_template_token ['spent_time', 'time_spent'], Proc.new{|crm_case| crm_case.time_entries.sum(:hours).to_i.to_s}
  easy_mail_template_token 'assignee', Proc.new{|crm_case| crm_case.assigned_to.nil? ? l(:label_nobody) : crm_case.assigned_to.name}
  easy_mail_template_token 'external_assignee', Proc.new{|crm_case| crm_case.external_assigned_to.nil? ? l(:label_nobody) : crm_case.external_assigned_to.name}
  easy_mail_template_token 'crm_case_note', Proc.new{|crm_case| crm_case.journals.last.try(:notes).to_s}
  #easy_mail_template_token 'user_signature', l(:field_id), Proc.new{|crm_case| crm_case.journals.last.notes if crm_case.journals.any?}

  #  def easy_helpdesk_replace_tokens(text)
  #    t = text.to_s.dup
  #    t = t.gsub(/%\s?crm_case_id\s?%/, '#' + self.id.to_s)
  #    t = t.gsub(/%\s?crm_case_name\s?%/, self.name.to_s)
  #    t = t.gsub(/%\s?spent_time\s?%|%\s?time_spent\s?%/, self.time_entries.sum(:hours).to_i.to_s)
  #    if self.assigned_to
  #      t = t.gsub(/%\s?assignee\s?%/, self.assigned_to.name)
  #    else
  #      t = t.gsub(/%\s?assignee\s?%/, l(:label_nobody))
  #    end
  #    if t.match(/%\s?crm_case_note\s?%/)
  #      t = t.gsub(/%\s?crm_case_note\s?%/, self.journals.last.notes) if self.journals.any?
  #    end
  #
  #    self.custom_field_values.each do |cf_value|
  #      t = t.gsub(Regexp.new("%\s?task_cf_#{cf_value.custom_field.id}\s?%"), cf_value.value.to_s)
  #    end
  #
  #    if signature = User.current.easy_helpdesk_mail_signatures.first
  #      t = t.gsub(/%\s?user_signature\s?%/, signature.signature)
  #    end
  #    t
  #  end

  before_validation :convert_empty_string
  before_save :set_previous_assignee
  before_save :set_contract_date
  before_save :force_updated_on_change
  before_save :set_easy_last_updated_by_id
  before_save :set_closed_on_and_closed_by
  before_create :set_default_assignee
  after_save :create_journal
  after_create_commit :send_notification_added
  after_update :remove_watchers, if: proc { |easy_crm_case| easy_crm_case.saved_change_to_project_id? }
  after_update_commit if: proc { |easy_crm_case| easy_crm_case.main_easy_contact_id && Redmine::Plugin.installed?(:easy_computed_custom_fields) } do
    EasyCrm::RecalculateEasyContactFields.perform_later(self)
  end

  alias_attribute :customer, :main_easy_contact

  def self.visible_condition(user, options={})
    return Project.allowed_to_condition(user, :view_easy_crms, options) if user.admin?

    Project.allowed_to_condition(user, :view_easy_crms, options) do |role, user|
      if role.easy_crm_cases_visibility == 'all'
        '1=1'
      elsif role.easy_crm_cases_visibility == 'own' && user.id && user.logged?
        user_ids = [user.id] + user.group_ids
        "(#{table_name}.author_id = #{user.id} OR #{table_name}.assigned_to_id IN (#{user_ids.join(',')}) OR #{table_name}.external_assigned_to_id IN (#{user_ids.join(',')}) OR EXISTS (SELECT w.id FROM #{Watcher.table_name} w WHERE w.watchable_type = 'EasyCrmCase' AND w.watchable_id = #{EasyCrmCase.table_name}.id AND w.user_id = #{user.id}))"
      else
        '1=0'
      end
    end
  end

  def self.css_icon
    'icon icon-crm-1 easy-crm'
  end

  def self.easy_merge_and_close_crms(crms, merge_to)
    return false if crms.count == 1 && crms.first == merge_to

    crms = crms - [merge_to]
    merged = true
    updated_description = merge_to.description.to_s.dup

    crms.each do |crm|
      merged = false if !crm.easy_merge_to(merge_to)
      Mailer.with_deliveries(false) do
        crm.init_journal(User.current, I18n.t(:label_merged_into, id: "easy_crm_case##{merge_to.id}")).save
      end
      updated_description << easy_merge_entity_description(crm)
    end

    begin
      merge_to.description = updated_description
      Mailer.with_deliveries(false) do
        merge_to.save
      end
    rescue ActiveRecord::StaleObjectError
      # if it is parent, it is changed during merging
      merge_to.reload
      merge_to.description = updated_description
      Mailer.with_deliveries(false) do
        merge_to.save
      end
    end

    merged
  end

  def easy_crm_case_status_id=(easy_crm_case_status_id)
    if easy_crm_case_status_id.to_s != self.easy_crm_case_status_id.to_s
      self.easy_crm_case_status = (easy_crm_case_status_id.present? ? EasyCrmCaseStatus.find_by(id: easy_crm_case_status_id) : nil)
    end
    self.easy_crm_case_status_id
  end

  def easy_crm_case_status=(easy_crm_case_status)
    status_was = self.easy_crm_case_status
    association(:easy_crm_case_status).writer(easy_crm_case_status)
    if easy_crm_case_status != status_was
      # reassign custom field values to ensure compliance with workflow
      reassign_custom_field_values
      @read_only_attribute_names = nil
      @workflow_rules = nil
    end
  end

  def set_easy_crm_case_status_by_internal_name(easy_crm_case_status_internal_name)
    self.easy_crm_case_status = easy_crm_case_status_internal_name.presence && EasyCrmCaseStatus.find_by(internal_name: easy_crm_case_status_internal_name)
    self.easy_crm_case_status
  end

  def easy_merge_to(entity_to_merge)
    entity_to_merge_class = entity_to_merge.class
    #
    # selected entities to copy
    # for example: related entities is not necessary to copy
    #
    entities_types_to_copy = {'Journal' => 1, 'Attachment' => 1, 'EasyCrmCaseItem' => 1, 'EasyContactEntityAssignment' => 1, 'EasyInvoice' => 1}

    associations_to_merge = entity_to_merge_class.reflections.collect { |assoc| assoc[0].to_sym } # get all associations
    associations_to_merge -= [:custom_values]
    associations_to_merge.each do |association|
      assoc = association.to_s
      reflection = entity_to_merge_class.reflections[assoc]

      case reflection.macro
        when :has_and_belongs_to_many, :has_many
          entities = self.send(assoc)
          next if entities.blank?

          entities.each do |r|
            duplicate = easy_duplicate_entity_for_merge(r, entities_types_to_copy)
            begin
              Mailer.with_deliveries(false) do
                # check if object does not already contain duplicate in its associtation
                # if Duplicate Entry exception is raised, then object with association cannot be saved
                if entities_types_to_copy[r.class.name] || !entity_to_merge.send(assoc).include?(duplicate)
                  entity_to_merge.send(assoc) << duplicate
                end
              end
            rescue StandardError => e
              # association already contains duplicate object
              # read only associations
              entity_to_merge.reload
            end
          end
        end
      end

    self.reload
    self.is_canceled = true
    Mailer.with_deliveries(false) do
      self.save
    end
  end

  def easy_duplicate_entity_for_merge(original, entities_types_to_copy)
    duplicate = original
    if entities_types_to_copy[original.class.name]
      begin
        duplicate = original.dup
        if original.is_a?(EasyInvoice)
          Mailer.with_deliveries(false) do
            self.easy_crm_case_items.each do |easy_crm_case_item|
              duplicate.build_from_easy_crm_case_item(easy_crm_case_item)
            end
          end
        end
      rescue StandardError => e
        # cannot duplicate object, use original instead
      end
    end
    duplicate
  end

  def self.easy_merge_entity_description(merging_entity)
    "\r\n" << '-' * 60 << ' ' << I18n.t(:label_merged_from, :ids => "easy_crm_case##{merging_entity.id}") << "\r\n" << merging_entity.description.to_s
  end

  def build_from_easy_invoice(easy_invoice)
    self.easy_invoices << easy_invoice
    self.contract_date ||= easy_invoice.issued_at
    self.easy_contacts << easy_invoice.client if easy_invoice.client

    easy_invoice.easy_invoice_line_items.each do |easy_invoice_line_item|
      build_from_easy_invoice_line_item(easy_invoice_line_item)
    end

    self
  end

  def build_from_easy_invoice_line_item(easy_invoice_line_item)
    self.easy_crm_case_items.build(
        amount: easy_invoice_line_item.quantity,
        name: easy_invoice_line_item.name,
        price_per_unit: easy_invoice_line_item.unit_price,
        unit: easy_invoice_line_item.unit_name,
        total_price: easy_invoice_line_item.total
    )
  end

  # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
  def available_custom_fields
    if @available_custom_fields
      return @available_custom_fields
    end

    easy_crm_case_status ? easy_crm_case_status.custom_fields.with_group.sorted.to_a : []
  end

  def self.load_available_custom_fields(crm_cases)
    # { crm_status => *CF }
    custom_fields_for_status = Hash.new { |hash, key| hash[key] = [] }

    all_status_ids = crm_cases.map(&:easy_crm_case_status_id)
    custom_fields = EasyCrmCaseCustomField.with_group.
                                           includes(:easy_crm_case_statuses).
                                           where(easy_crm_case_statuses: { id: all_status_ids }).
                                           sorted
    custom_fields.each do |custom_field|
      custom_field.easy_crm_case_statuses.each do |crm_status|
        custom_fields_for_status[crm_status.id] << custom_field
      end
    end

    crm_cases.each do |crm_case|
      crm_case.instance_variable_set(:@available_custom_fields, custom_fields_for_status[crm_case.easy_crm_case_status_id])
    end
  end

  def deletable?(user = nil)
    user ||= User.current
    user.allowed_to?(:delete_easy_crm_cases, self.project)
  end

  def editable?(user = nil)
    user ||= User.current
    user.allowed_to?(:edit_easy_crm_cases, self.project) ||
      (user.allowed_to?(:edit_own_easy_crm_cases, self.project) &&
        [self.author_id, self.assigned_to_id, self.external_assigned_to_id].include?(user.id))
  end

  def visible?(user = nil)
    (user || User.current).allowed_to?(:view_easy_crms, self.project) do |role, user|
      if role.easy_crm_cases_visibility == 'all'
        true
      elsif role.easy_crm_cases_visibility == 'own'
        self.author == user || user.is_or_belongs_to?(assigned_to) || user.is_or_belongs_to?(external_assigned_to) || self.watcher_user_ids.include?(user.id)
      else
        false
      end
    end
  end

  alias_method :attachments_visible?, :visible?
  alias_method :attachments_editable?, :editable?
  alias_method :attachments_deletable?, :editable?

  def overdue?
    !contract_date.nil? && (contract_date < Date.today)
  end

  def css_classes(user=nil, options={})
    user ||= User.current
    inline_editable = options[:inline_editable] != false
    s = "easy-crm-case status-#{self.easy_crm_case_status_id}"
    s << ' overdue' if overdue?
    if user.logged?
      s << ' created-by-me' if self.author_id == user.id
      s << ' assigned-to-me' if self.assigned_to_id == user.id
      if EasyUserType.easy_type_partner.any?
        s << ' external-assigned-to-me' if self.external_assigned_to_id == user.id
      end
      s << ' multieditable-container' if inline_editable
    end
    s
  end

  def visible_custom_field_values(user=nil)
    user_real = user || User.current

    custom_field_values.select do |value|
      value.custom_field.visible_by?(project, user_real)
    end
  end

  def run_invoice_generation?
    false
  end

  def editable_custom_field_values(user = nil)
    read_only_attr_names_array = read_only_attribute_names(user)
    visible_custom_field_values(user).reject do |value|
      read_only_attr_names_array.include?(value.custom_field_id.to_s)
    end
  end

  def editable_custom_fields(user=nil)
    editable_custom_field_values(user).map(&:custom_field).uniq
  end

  def next_action=(value)
    value = if self.all_day
      value.is_a?(Hash) ? value[:date] : value
    else
      EasyUtils::DateUtils.build_datetime_from_params(value)
    end
    super(value)
  end

  def next_action
    (self.all_day && self[:next_action]) ? self[:next_action].to_date : super
  end

  def next_action_date
    self.next_action ? self.next_action_in_zone.to_date : nil
  end

  def next_action_in_zone
    self.next_action ? User.current.user_time_in_zone(self.next_action) : nil
  end

  def to_s
    self.name.to_s
  end

  alias :base_reload :reload
  def reload(*args)
    @assignable_users = nil
    @external_assignable_users = nil
    base_reload(*args)
  end

  def get_easy_mail_template
    EasyCrm::EasyMailTemplateEasyCrmCase
  end

  def total_spent_hours
    @total_spent_hours ||= self.time_entries.sum(:hours).to_f || 0.0
  end

  def last_journal_id
    if self.new_record?
      nil
    else
      self.journals.maximum(:id)
    end
  end

  def journals_after(journal_id = nil)
    scope = self.journals.reorder("#{Journal.table_name}.id ASC")
    if journal_id.present?
      scope = scope.where("#{Journal.table_name}.id > ?", journal_id.to_i)
    end
    scope
  end

  def previous_assignee
    # assigned_to_id_was is reset before after_save callbacks
    user_id = @previous_assigned_to_id || assigned_to_id_before_last_save
    if user_id && user_id != assigned_to_id
      @previous_assignee ||= User.find_by(id: user_id)
    end
  end

  def previous_external_assignee
    external_user_id = @previous_external_assigned_to_id || external_assigned_to_id_before_last_save
    if external_user_id && external_user_id != external_assigned_to_id
      @previous_external_assignee ||= User.find_by(id: external_user_id)
    end
  end

  def convert_empty_string
    self.price = self.price.presence
    self.probability = self.probability.presence
  end

  def set_previous_assignee
    @previous_assigned_to_id = assigned_to_id_was
    @previous_external_assigned_to_id = external_assigned_to_id_was
  end

  def set_contract_date
    self.contract_date = Date.today if easy_crm_case_status_id_changed?  && easy_crm_case_status.try(:is_paid?)
  end

  def set_total_price
    self.price = self.easy_crm_case_items.inject(0.0){|acc, x| acc + x.total_price } if EasySetting.value('easy_crm_use_items', project)
  end

  def clear_previous_assignee
    @previous_assignee = nil
    @previous_assigned_to_id = nil
    @previous_external_assignee = nil
    @previous_external_assigned_to_id = nil
  end

  def notified_users
    notified = []
    notified << self.author if self.author
    if self.assigned_to
      notified.concat(self.assigned_to.is_a?(Group) ? self.assigned_to.users : [self.assigned_to])
    end
    if self.external_assigned_to
      notified.concat(self.external_assigned_to.is_a?(Group) ? self.external_assigned_to.users : [self.external_assigned_to])
    end
    if previous_assignee
      notified.concat(previous_assignee.is_a?(Group) ? previous_assignee.users : [previous_assignee])
    end
    notified.concat(watcher_users.to_a)
    notified = notified.select {|u| u.active? && u.notify_about?(self)}

    notified.concat(self.project.notified_users)
    notified.uniq!
    # Remove users that can not view the issue
    notified.reject! {|user| !self.visible?(user)}
    notified
  end

  def recipients
    self.notified_users.collect(&:mail)
  end

  def assignable_users
    return @assignable_users unless @assignable_users.nil?
    user_ids = []
    user_ids << author_id if author && author.active?
    user_ids << assigned_to_id if assigned_to

    if project
      project_scope = project.assignable_users
      if user_ids.empty?
        @assignable_users = project_scope.to_a
        return @assignable_users
      end
      user_ids.concat project_scope.reorder(nil).pluck(:id)
    end

    @assignable_users = user_ids.empty? ? [] : User.where(id: user_ids).easy_type_regular.sorted.to_a
  end

  def external_assignable_users
    return @external_assignable_users unless @external_assignable_users.nil?
    user_ids = []
    user_ids << external_assigned_to_id if external_assigned_to

    if project
      project_scope = project.assignable_users
      if user_ids.empty?
        @external_assignable_users = project_scope.to_a
        return @external_assignable_users
      end
      user_ids.concat project_scope.reorder(nil).pluck(:id)
    end

    @external_assignable_users = user_ids.empty? ? [] : User.where(id: user_ids).easy_type_partner.sorted.to_a
  end

  def created_date
    self.created_at.to_date
  end

  def required_attribute?(name, user=nil)
    required_attribute_names(user).include?(name.to_s)
  end

  def safe_attribute_names(user=nil)
    names = super
    names -= read_only_attribute_names(user)
    names
  end

  def easy_journal_option(option, journal)
    case option
    when :title
      journal.journalized.to_s
    when :type
      ''
    when :url
      {:controller => 'easy_crm_cases', :action => 'show', :id => journal.journalized_id, :anchor => "change-#{journal.id}"}
    end
  end

  def safe_attributes=(attrs, user=User.current)
    attrs = attrs.to_unsafe_hash if attrs.respond_to?(:to_unsafe_hash)
    return unless attrs.is_a?(Hash)
    attrs = attrs.deep_dup
    if (s = attrs.delete('project_id'))
      self.project_id = s
    end
    if (s = attrs.delete('easy_crm_case_status_id')) && safe_attribute?('easy_crm_case_status_id')
      self.easy_crm_case_status_id = s
    end
    super(attrs, user)
  end

  def required_attribute_names(user=nil)
    @required_attribute_names ||= workflow_rule_by_attribute.reject {|attr, rule| rule != 'required'}.keys
  end

  def read_only_attribute_names(user=nil)
    @read_only_attribute_names ||= workflow_rule_by_attribute.reject {|attr, rule| rule != 'readonly'}.keys
  end

  private

  def issue_related_contact(obj)
    obj.easy_contact_ids += self.easy_contact_ids - obj.easy_contact_ids
  rescue ActiveRecord::RecordNotUnique
  end

  def attachment_added(obj)
    if @current_journal && !obj.new_record?
      @current_journal.details << JournalDetail.new(:property => 'attachment', :prop_key => obj.id, :value => obj.filename)
    end
  end

  # Callback on attachment deletion
  def attachment_removed(obj)
    if @current_journal && !obj.new_record?
      @current_journal.details << JournalDetail.new(:property => 'attachment', :prop_key => obj.id, :old_value => obj.filename)
      @current_journal.save
    end
  end

  # Make sure updated_at is updated when adding a note and set updated_at now
  def force_updated_on_change
    return true if new_record?
    if @current_journal || changed?
      self.updated_at = current_time_from_proper_timezone
    end
  end

  def send_notification_added
    if Setting.notified_events.include?('easy_crm_case_added')
      EasyCrmMailer.deliver_easy_crm_case_added(self)
    end
  end

  def set_default_assignee
    self.assigned_to_id = EasySetting.value('crm_default_assignee', project) unless self.assigned_to_id
    self.external_assigned_to_id = EasySetting.value('crm_default_external_assignee', project) unless self.external_assigned_to_id
    true
  end

  def remove_watchers #removes watchers if user is not a member of new project
    self.watcher_users = (self.project.users & self.watcher_users)
  end

  def self.fields_for_order_statement(table=nil)
    table ||= table_name
    ["#{table}.name"]
  end

  def workflow_rule_by_attribute
    @workflow_rules ||=
    if User.current.admin? && EasySetting.value('skip_workflow_for_admin', project)
      {}
    else
      workflow_crm_permissions = WorkflowCrmPermission.where(old_status_id: easy_crm_case_status_id).to_a
      workflow_rules = workflow_crm_permissions.inject({}) do |h,wcp|
        h[wcp.field_name] = wcp.rule
        h
      end
      EasyCrmCaseCustomField.where(visible: false).pluck(:id).each do |field_id|
        workflow_rules[field_id.to_s] = 'readonly'
      end
      workflow_rules
    end
  end

  # TODO: DRY
  def validate_required_fields
    return true if User.current.admin? && EasySetting.value('skip_workflow_for_admin', project)

    user = new_record? ? author : current_journal.try(:user)

    required_attribute_names(user).each do |attribute|
      if /^\d+$/.match?(attribute)
        attribute = attribute.to_i
        v = custom_field_values.detect {|v| v.custom_field_id == attribute }
        if v && v.value.blank?
          errors.add :base, v.custom_field.name + ' ' + l('activerecord.errors.messages.blank')
        end
      else
        if respond_to?(attribute) && send(attribute).blank?
          errors.add attribute, :blank
        end
      end
    end
  end

  def validate_status_only_for_admin
    user = User.current
    errors.add(:base, l(:label_validation_only_for_admin)) if easy_crm_case_status && easy_crm_case_status_id_changed? && easy_crm_case_status.only_for_admin && !user.easy_lesser_admin_for?(:easy_crm)
  end

  def validate_custom_field_values
    editable_custom_field_values.each(&:validate_value)
  end

  def date_for_price_recalculation
    contract_date || updated_at
  end

  def set_easy_last_updated_by_id
    self.easy_last_updated_by_id = current_journal.try(:user_id) || User.current.id if changed.detect {|x| x != 'updated_at'}
  end

  def set_closed_on_and_closed_by
    if easy_crm_case_status_id_changed? && easy_crm_case_status.try(:is_closed?) || is_canceled_changed? && is_canceled? || is_finished_changed? && is_finished?
      self.easy_closed_by = User.current
      self.closed_on = updated_at
    end
  end

end
