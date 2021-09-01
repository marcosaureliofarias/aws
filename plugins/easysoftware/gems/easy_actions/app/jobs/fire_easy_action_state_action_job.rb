class FireEasyActionStateActionJob < EasyActionsJob

  def perform(easy_action_state_action)
    easy_action_state_action.fire
  end

end
