class EasyActionSequenceInstance < ActiveRecord::Base
  include Easy::Redmine::BasicEntity

  belongs_to :easy_action_sequence
  belongs_to :current_state, class_name: 'EasyActionState', foreign_key: 'current_easy_action_state_id', optional: true
  belongs_to :entity, polymorphic: true
  has_one :template, through: :easy_action_sequence, class_name: 'EasyActionSequenceTemplate'

  enum status: { waiting: 0, running: 1, done: 5 }, _prefix: :status

  scope :for, ->(entity) { where(entity: entity) }

  store :settings, coder: JSON

  safe_attributes 'entity_type', 'entity_id', 'settings'

  def name
    template&.name
  end

end
