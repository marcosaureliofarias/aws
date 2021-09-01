class EasyGlobalRating < ActiveRecord::Base

  belongs_to :customized, :polymorphic => true

  validates :customized, :presence => true

end
