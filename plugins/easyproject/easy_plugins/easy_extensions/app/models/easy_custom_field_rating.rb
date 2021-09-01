class EasyCustomFieldRating < ActiveRecord::Base
  belongs_to :custom_value
  belongs_to :user

  validates :custom_value_id, :presence => true
  validates_uniqueness_of :user_id, :scope => :custom_value_id, :if => :user_id?
end
