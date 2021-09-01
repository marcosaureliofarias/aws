class EasyActionSequence < ActiveRecord::Base
  include Easy::Redmine::BasicEntity

  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  belongs_to :template, class_name: 'EasyActionSequenceTemplate', foreign_key: 'easy_action_sequence_template_id'
  belongs_to :entity, polymorphic: true

  has_many :instances, class_name: 'EasyActionSequenceInstance', dependent: :destroy

  safe_attributes 'easy_action_sequence_template_id', 'entity_type', 'entity_id'

  def create_new_instances
    new_target_entities.each do |entity|
      instances.create(entity: entity, current_state: template.initial_state)
    end
  end

  private

  def new_target_entities
    template.condition.new_entities_for(self)
  end

end
