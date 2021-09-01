class EasyActionSequenceInstancePlannerJob < EasyActionsJob

  def perform
    EasyActionSequenceInstance.status_waiting.each do |easy_action_sequence_instance|
      EasyActionSequenceInstanceEngineJob.perform_later(easy_action_sequence_instance)
    end
  end

end
