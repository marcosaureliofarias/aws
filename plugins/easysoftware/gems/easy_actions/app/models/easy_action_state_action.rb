class EasyActionStateAction < ActiveRecord::Base
  include Easy::Redmine::BasicEntity
  include EasyActions::EasyActionEntity

  belongs_to_parent :easy_action_sequence_template
  belongs_to :easy_action_state

  validates :name, presence: true

  safe_attributes 'name', 'easy_action_state_id'

  def ident
    :"action_#{id}"
  end

end
