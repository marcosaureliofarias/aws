class EasyFavorite < ActiveRecord::Base
  belongs_to :user
  belongs_to :entity, :polymorphic => true
  validates :user, :entity, :presence => true
  validates :user_id, :uniqueness => { :scope => [:entity_id, :entity_type] }
end
