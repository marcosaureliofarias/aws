class EasyToDoList < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :user
  has_many :easy_to_do_list_items, dependent: :destroy

  scope :sorted, -> { order(position: :asc) }

  acts_as_positioned scope: :user_id

  validates :name, presence: true, length: { maximum: 255 }

  safe_attributes 'name', 'position'

end
