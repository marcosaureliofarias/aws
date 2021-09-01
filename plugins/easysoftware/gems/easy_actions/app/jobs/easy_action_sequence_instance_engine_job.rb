class EasyActionSequenceInstanceEngineJob < EasyActionsJob

  def perform(easy_action_sequence_instance)
    return if !easy_action_sequence_instance.status_waiting?
    return if !easy_action_sequence_instance.entity

    machine = EasyActions::StateMachine.new(easy_action_sequence_instance)
    machine.run
  end
end
