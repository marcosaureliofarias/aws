class EasyEntityActionHistory < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :easy_entity_action
  belongs_to :entity, :polymorphic => true

  def self.css_icon
    'icon icon-history'
  end

end
