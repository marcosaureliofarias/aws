class EasyBroadcast < ActiveRecord::Base
  include Redmine::SafeAttributes

  has_and_belongs_to_many :easy_user_types

  belongs_to :author, class_name: 'User'

  scope :visible, lambda { |*args|
    where(EasyBroadcast.visible_condition(args.shift || User.current, *args))
  }

  scope :active_now, -> { where('end_at > :t AND start_at < :t', { t: Time.now }) }

  scope :active_for_current_user, -> (user = User.current) {
    scope = active_now
    scope = scope.joins(:easy_user_types).where(easy_user_types: { id: user.easy_user_type_id }) unless user.admin?
    scope.where.not(id: EasyUserReadEntity.where(entity_type: EasyBroadcast.name, user_id: user.id).select(:entity_id))
  }

  validates :author_id, :start_at, :end_at, presence: true
  validates :message, length: { minimum: 1, maximum: 1.kilobytes }, presence: true
  validate :validate_time_range, if: -> { start_at && end_at }

  safe_attributes 'message', 'start_at', 'end_at', 'author_id', 'easy_user_type_ids', if: ->(entity, user) { entity.editable?(user) }

  acts_as_user_readable

  def ensure_my_record
    true
  end

  def self.visible_condition(user, options = {})
    '1=1'
  end

  def self.css_icon
    'icon icon-mute'
  end

  def project
    nil
  end

  def visible?(user = nil)
    user ||= User.current
    # user.allowed_to_globally?(:view_easy_broadcasts)
    user.logged?
  end

  def editable?(user = nil)
    user ||= User.current
    user.allowed_to_globally?(:manage_easy_broadcasts)
  end

  def deletable?(user = nil)
    user ||= User.current
    user.allowed_to_globally?(:manage_easy_broadcasts)
  end

  def created_on
    created_at
  end

  def updated_on
    updated_at
  end

  def notified_users
    if project
      project.notified_users.reject { |user| !visible?(user) }
    else
      [User.current]
    end
  end

  def validate_time_range
    if self.start_at > self.end_at
      errors.add :base, l(:error_easy_broadcast_end_less_then_start)
    end
    broadcasts = EasyBroadcast.where('(start_at <= :start AND :start <= end_at) OR (start_at <= :end AND :end <= end_at) OR (:start < start_at AND end_at < :end)', { start: self.start_at, end: self.end_at })
                     .eager_load(:easy_user_types)
                     .where('easy_user_types.id is ? OR easy_user_types.id in (?)', nil, self.easy_user_type_ids).distinct
    #.where.not(id: self.id) # nil if new_record?

    if (self.new_record? ? broadcasts : broadcasts -= [self]).present?
      errors.add :base, l(:error_broadcast_time_range, broadcast_ids: broadcasts.map { |b| "<a href='#{Setting.protocol}://#{Setting.host_name}/easy_broadcasts/#{b.id}'> #{b.id} </a>" }.join(',')).html_safe
    end
  end

end