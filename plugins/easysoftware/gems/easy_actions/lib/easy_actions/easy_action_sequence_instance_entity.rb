module EasyActions
  module EasyActionSequenceInstanceEntity
    extend ActiveSupport::Concern

    included do

      has_many :easy_action_sequence_instances, as: :entity, class_name: 'EasyActionSequenceInstance', dependent: :destroy

    end

    class_methods do
    end

  end
end
