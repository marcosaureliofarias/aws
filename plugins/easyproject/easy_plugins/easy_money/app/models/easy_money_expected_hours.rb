class EasyMoneyExpectedHours < ActiveRecord::Base

  belongs_to :entity, :polymorphic => true

  validates :entity_type, :presence => true
  validates :entity_id, :presence => true
  validates_numericality_of :hours, :allow_nil => false, :only_integer => true, :greater_than_or_equal_to => 0

end
