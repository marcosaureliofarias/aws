class EasyUserReadEntity < ActiveRecord::Base

  belongs_to :user
  belongs_to :entity, :polymorphic => true
  validates :user_id, :uniqueness => { :scope => [:entity_id, :entity_type] }

  scope :for_user, ->(user = nil) { user ||= User.current; where(user_id: user) }

  after_initialize :default_values

  def default_values
    self.read_on = Time.now if new_record? && self.read_on.nil?
  end

end
