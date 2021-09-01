module EasyActions
  module EasyActionSequenceEntity
    extend ActiveSupport::Concern

    included do

      has_many :easy_action_sequences, as: :entity, class_name: 'EasyActionSequence', dependent: :destroy
      has_many :easy_action_sequence_instances, through: :easy_action_sequences, source: :instances, class_name: 'EasyActionSequenceInstance', dependent: :destroy

    end

    class_methods do
    end

  end
end
