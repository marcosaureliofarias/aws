# encoding: utf-8
class EasyContactGroup < ActiveRecord::Base
  include Redmine::SafeAttributes

  self.table_name = 'easy_contacts_groups'
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :entity, :polymorphic => true
  has_and_belongs_to_many :easy_contacts, :class_name => 'EasyContact', :join_table => 'easy_contacts_group_assignments', :foreign_key => 'group_id', :association_foreign_key => 'contact_id', :after_add => :assign_to_entity_if_needed

  scope :global_groups, lambda { where(["#{self.table_name}.entity_id IS NULL"]) }

  html_fragment :author_note, :scrub => :strip

  attr_accessor :additional_custom_fields
  attr_accessor :current_journal

  safe_attributes 'author_note'
  safe_attributes 'notes', :if => lambda {|easy_contact_group, user| easy_contact_group.commentable?(user) && !easy_contact_group.new_record? }
  safe_attributes 'group_name', 'is_public', 'author_id', 'parent_id', 'entity_id', 'entity_type', 'root_id'

  # acts_as_nested_set :scope => 'root_id' / issue using root_id scope
  include Redmine::NestedSet::IssueNestedSet
  acts_as_customizable
  acts_as_attachable

  acts_as_easy_journalized :non_journalized_columns => ['author_note'], :format_detail_boolean_columns => ['is_public'],
    :format_detail_reflection_columns => ['author_id']

  validates :group_name, :length => { :in => 1..50 }, :allow_nil => false
  validate :validate_parent, if: -> { parent_id.present? }

  before_save :check_author_note

  after_initialize :default_values
  after_save :create_journal

  alias_attribute :groups, :easy_contacts

  delegate :notes, :notes=, :to => :current_journal, :allow_nil => true

  def default_values
    self.author_id = User.current.id if new_record? && self.author_id.nil?
    self.additional_custom_fields = []
  end

  def self.project_groups(project_id)
    EasyContactGroup.where(:entity_type => 'Project', :entity_id => project_id)
  end

  def self.project_groups_root(project_id)
    EasyContactGroup.where(:entity_type => 'Project', :entity_id => project_id, :parent_id => nil)
  end

  def project_root?
    (self.entity_type == 'Project' && self.entity_id != nil && self.parent_id == nil) ? true : false
  end
  #alias
  def name
    group_name
  end

  def to_s
    group_name
  end

  def allowed_parents
    return @allowed_parents if @allowed_parents
    @allowed_parents = EasyContactGroup.all
    @allowed_parents = @allowed_parents - self_and_descendants
    #if User.current.allowed_to?(:add_project, nil, :global => true) || (!new_record? && parent.nil?)
    @allowed_parents << nil
    #end
    unless parent.nil? || @allowed_parents.empty? || @allowed_parents.include?(parent)
      @allowed_parents << parent
    end
    @allowed_parents
  end

  def set_allowed_parent!(p)
    unless p.nil? || p.is_a?(EasyContactGroup)
      if p.to_s.blank?
        p = nil
      else
        p = EasyContactGroup.find_by_id(p)
        return false unless p
      end
    end
    if p.nil?
      if !new_record? && allowed_parents.empty?
        return false
      end
    elsif !allowed_parents.include?(p)
      return false
    end
    set_parent!(p)
  end

  def set_parent!(p)
    unless p.nil? || p.is_a?(EasyContactGroup)
      if p.to_s.blank?
        p = nil
      else
        p = EasyContactGroup.find_by_id(p)
        return false unless p
      end
    end
    if p == parent && !p.nil?
      # Nothing to do
      true
    elsif p.nil? || (move_possible?(p))
      # Insert the project so that target's children or root projects stay alphabetically sorted
      sibs = (p.nil? ? self.class.roots : p.children)
      to_be_inserted_before = sibs.detect {|c| c.group_name.to_s.downcase > group_name.to_s.downcase }
      if to_be_inserted_before
        move_to_left_of(to_be_inserted_before)
      elsif p.nil?
        if sibs.empty?
          # move_to_root adds the project in first (ie. left) position
          move_to_root
        else
          move_to_right_of(sibs.last) unless self == sibs.last
        end
      else
        # move_to_child_of adds the project in last (ie.right) position
        move_to_child_of(p)
      end
      true
    else
      # Can not move to the given target
      false
    end
  end

  # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
  def available_custom_fields
    if new_record?
      fields = (((self.class) ? EasyContactGroupCustomField.all.select {|c| c.is_primary } : []) + self.additional_custom_fields.to_a).uniq
    else
      fields = (custom_values.collect{|c| c.custom_field} + self.additional_custom_fields).uniq
    end

    fields.size > 0 ? fields.sort_by(&:position) : fields
  end

  def unused_non_primary_custom_fields
    ((self.class) ? EasyContactGroupCustomField.all.select {|c| !c.is_primary } : []) || []
  end

  def add_non_primary_custom_fields(custom_fields)
    custom_fields = custom_fields.dup
    self.additional_custom_fields = []
    unless custom_fields.blank?
      available_custom_fields.each do |custom_field|
        custom_fields.delete custom_field.id.to_s
      end

      custom_fields.each do |custom_field_id|
        self.additional_custom_fields << EasyContactGroupCustomField.find(custom_field_id[0])
      end
    end
  end

  # attachments dance
  def project
    nil
  end

  def attachments_visible?(user=User.current)
    user.allowed_to?(self.class.attachable_options[:view_permission], self.project)
  end

  def attachments_deletable?(user=User.current)
    user.allowed_to?(self.class.attachable_options[:delete_permission], self.project)
  end

  def self.group_type_sql
    "CASE #{EasyContactGroup.table_name}.entity_type WHEN 'Project' THEN 'filter.project_groups' WHEN 'Principal' THEN 'filter.personal_groups' ELSE 'filter.global_groups' END"
  end

  def group_type
    case self.entity_type
    when 'Project'
      'filter.project_groups'
    when 'Principal'
      'filter.personal_groups'
    else
      'filter.global_groups'
    end
  end

  def global?
    return self.entity_type.nil?
  end

  def project_group?
    return self.entity_type == 'Project'
  end

  def commentable?(user=User.current)
    return @commentable unless @commentable.nil?
    @commentable = user.allowed_to_globally?(:add_note_easy_contact_groups, {})
    @commentable
  end

  def validate_parent
    errors.add(:parent, :invalid) if !parent_id.nil? && saved_change_to_parent_id? && self_and_descendants.exists?(parent_id)
  end

  private

  def assign_to_entity_if_needed(contact)
    self.entity.easy_contacts << contact unless self.global?
  end

  def check_author_note
    unless self.author_note.blank?
      self.author_note = nil if Sanitize.clean(self.author_note).strip.sub(/\302\240/, '').blank?
    end
  end

end

