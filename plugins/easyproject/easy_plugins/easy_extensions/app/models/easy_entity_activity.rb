class EasyEntityActivity < ActiveRecord::Base
  include Redmine::SafeAttributes
  include EasyEntityActivityScope

  belongs_to :entity, polymorphic: true, validate: false
  belongs_to :issue, -> { joins("INNER JOIN #{EasyEntityActivity.table_name} ON #{EasyEntityActivity.table_name}.entity_type = 'Issue' AND #{EasyEntityActivity.table_name}.entity_id = #{Issue.table_name}.id") }, foreign_key: :entity_id
  alias_method :issue, :entity
  belongs_to :category, class_name: 'EasyEntityActivityCategory'
  belongs_to :author, class_name: 'User'

  validates :entity, :presence => true
  validates :category, :presence => true
  validate :validate_times

  attr_accessor :journal_note

  before_save :prepare_update_entity
  before_save :set_end_time
  after_save :update_entity
  after_initialize :set_default, if: :new_record?

  has_many :easy_entity_activity_attendees, dependent: :destroy
  has_many :easy_entity_activity_users, through: :easy_entity_activity_attendees, source: :entity, source_type: 'Principal'
  has_many :easy_entity_activity_contacts, through: :easy_entity_activity_attendees, source: :entity, source_type: 'EasyContact'

  safe_attributes 'author_id', 'category_id', 'is_finished', 'description', 'entity_id', 'entity_type', 'all_day', 'start_time', 'end_time'

  delegate :project, to: :entity

  DELTA = 15

  def prepare_update_entity
    details = { time: format_time(self.start_time), category: self.category }
    if self.new_record?
      @journal_note = (self.is_finished? ? l(:easy_entity_activity_was_reported, details) : l(:easy_entity_activity_is_planned, details)) + " : #{description}"
    elsif self.is_finished_changed?
      @journal_note = l(:easy_entity_activity_was_finished, details) + " : #{description}"
    end
  end

  def planned?
    persisted? && start_time && (created_at < start_time)
  end

  def update_entity
    begin
      entity.init_journal(User.current, @journal_note) if @journal_note.present?
      entity.save
    rescue ActiveRecord::StaleObjectError
      entity.reload
      entity.init_journal(User.current, @journal_note) if @journal_note.present?
      entity.save
    end
  end

  def start_date
    User.current.time_to_date(start_time)
  end

  def start_time=(value)
    super(EasyUtils::DateUtils.build_datetime_from_params(value))
  end

  def end_time=(value)
    super(EasyUtils::DateUtils.build_datetime_from_params(value))
  end

  def css_classes(user = nil, options = {})
    user            ||= User.current
    inline_editable = options[:inline_editable] != false
    if user.logged?
      s = ''
      s << ' created-by-me' if self.author_id == user.id
      s << ' multieditable-container' if inline_editable
    end
    s
  end

  def tr_css_classes
    s = 'entity-activity__item'
    s << ' entity-activity__item--desc' if description.blank?
    s << ' entity-activity__item--finished' if is_finished?
    s
  end

  def assignable_users
    User.active.sorted
  end

  def to_decorate(&block)
    yield(self) if block_given?
    self.start_time ||= User.current.user_time_in_zone
    self.end_time   ||= start_time + DELTA.minutes
    EasyEntityActivityDecorator.new(self)
  end

  def self.get_allowed_entity_types(user = nil)
    user ||= User.current
    allowed_entity_types = []
    allowed_entity_types << "EasyCrmCase" if user.allowed_to_globally?(:view_easy_crms)
    allowed_entity_types << "EasyContact" if user.allowed_to_globally?(:view_easy_contacts)
    allowed_entity_types
  end

  private

  def set_default
    self.author_id ||= User.current.id
    self.category ||= EasyEntityActivityCategory.default
  end

  def set_end_time
    self.end_time ||= start_time + DELTA.minutes if start_time
  end

  def validate_times
    if self.end_time && self.start_time && self.end_time < self.start_time
      self.errors.add(:base, l(:error_end_time_must_be_greater_than_start_time, scope: [:easy_entity_activity]))
    end
  end
end