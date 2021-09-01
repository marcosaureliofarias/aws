class EasyEntityActivityAttendee < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :easy_entity_activity
  belongs_to :entity, polymorphic: true

  safe_attributes 'entity_id', 'entity_type'

  delegate :to_s, to: :entity

  def self.all_attendees_values(term, limit = nil)
    users = User.active.visible.sorted.like(term).limit(limit).map { |u| { value: u.to_s + " (#{l :field_user})", id: 'Principal_' + u.id.to_s } }
    users.unshift({ value: "<< #{l(:label_me)} >>", id: 'me' }) if User.current.logged?
    users
  end

end
