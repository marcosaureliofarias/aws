class EasyActionSequenceTemplate < ActiveRecord::Base
  include Easy::Redmine::BasicEntity

  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  belongs_to :easy_action_sequence_category, optional: true

  has_many :states, class_name: 'EasyActionState', dependent: :destroy
  has_many :state_actions, class_name: 'EasyActionStateAction', through: :states
  has_many :transitions, class_name: 'EasyActionTransition', dependent: :destroy

  scope :like, ->(q) { where(arel_table[:name].matches("%#{q}%")) }

  validates :name, :target_entity_class, presence: true
  validates_associated :condition

  before_validation :before_validation_condition_class

  store :condition_settings, coder: JSON

  safe_attributes 'name', 'description', 'template_id', 'easy_action_sequence_category_id', 'condition_class', 'condition_settings'

  def initial_state
    @initial_state ||= states.where(initial: true).first
  end

  def condition
    return nil if condition_class.blank?

    if condition_class_changed?
      @condition ||= condition_class.safe_constantize&.new
    else
      @condition ||= condition_class.safe_constantize&.new(condition_settings)
    end
  end

  private

  def before_validation_condition_class
    self.target_entity_class = condition&.target_entity_class
  end

end
