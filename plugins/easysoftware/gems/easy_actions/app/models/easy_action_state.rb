class EasyActionState < ActiveRecord::Base
  include Easy::Redmine::BasicEntity

  belongs_to_parent :easy_action_sequence_template

  has_many :state_actions, class_name: 'EasyActionStateAction', dependent: :destroy

  scope :like, ->(q) { where(arel_table[:name].matches("%#{q}%")) }

  before_save :check_initial

  safe_attributes 'name', 'initial'

  def ident
    :"state_#{id}"
  end

  private

  def check_initial
    if initial? && initial_changed?
      easy_action_sequence_template.states.update_all(initial: false)
    elsif !initial? && easy_action_sequence_template.states.where(initial: true).count == 0
      self.initial = true
    end
  end


end
