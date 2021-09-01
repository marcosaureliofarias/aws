class EasyActionTransition < ActiveRecord::Base
  include Easy::Redmine::BasicEntity

  belongs_to_parent :easy_action_sequence_template
  belongs_to :state_from, class_name: 'EasyActionState'
  belongs_to :state_to, class_name: 'EasyActionState'

  scope :like, ->(q) { where(arel_table[:name].matches("%#{q}%")) }

  store :condition_settings, coder: JSON

  validates :condition_class, presence: true
  validates_associated :condition

  safe_attributes 'name', 'state_from_id', 'state_to_id', 'condition_class', 'condition_settings'

  def ident
    :"transition_#{id}"
  end

  def condition
    return nil if condition_class.blank?

    if condition_class_changed?
      @condition ||= condition_class.safe_constantize&.new
    else
      @condition ||= condition_class.safe_constantize&.new(condition_settings)
    end
  end

  def can_pass?(easy_action_sequence_instance)
    condition&.can_pass?(easy_action_sequence_instance)
  end

end
