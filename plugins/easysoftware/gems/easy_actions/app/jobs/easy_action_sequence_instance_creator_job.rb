class EasyActionSequenceInstanceCreatorJob < EasyActionsJob

  def perform
    EasyActionSequence.includes(:template).each do |easy_action_sequence|
      easy_action_sequence.create_new_instances
    end
  end

end
