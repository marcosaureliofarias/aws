class EasyToDoListItem < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :easy_to_do_list
  belongs_to :entity, polymorphic: true

  acts_as_positioned scope: :easy_to_do_list_id

  scope :sorted, -> { order(position: :asc) }

  validates :name, length: { maximum: 255 }
  validates :easy_to_do_list, presence: true, if: proc {|t| t.new_record? || t.easy_to_do_list_id_changed?}

  safe_attributes 'name', 'entity_id', 'entity_type', 'position', 'is_done', 'easy_to_do_list_id'
end
