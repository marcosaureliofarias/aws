module EasyActions
  class StateMachine

    def initialize(easy_action_sequence_instance)
      @instance = easy_action_sequence_instance
    end

    def run
      start_time = Time.now
      Rails.logger.debug "StateMachine: Entering for EasyActionSequenceInstance.find(#{@instance.id}) at #{start_time}"

      @instance.update_columns(status: :running)

      if next_transitions.any?
        if next_transitions.none? { |transition| trigger_transition(transition) }
          @instance.update_columns(status: :waiting)

          Rails.logger.debug "StateMachine: EasyActionSequenceInstance.find(#{@instance.id}) - stay waiting."
        end
      else
        @instance.update_columns(status: :done)

        Rails.logger.debug "StateMachine: EasyActionSequenceInstance.find(#{@instance.id}) - is done."
      end

      Rails.logger.debug "StateMachine: Exiting run at #{Time.now}, #{Time.now - start_time}s"
    end

    private

    def engine
      return @engine if @engine

      @engine = ::FiniteMachine.new(@instance, auto_methods: false)

      @engine.initial(@instance.easy_action_sequence.template.initial_state.ident)

      @instance.easy_action_sequence.template.transitions.preload(:state_from, :state_to).each do |transition|
        @engine.event transition.ident,
                      transition.state_from.ident => transition.state_to.ident,
                      if:                         ->(easy_action_sequence_instance) { transition.can_pass?(easy_action_sequence_instance) }
      end

      @engine.on_enter do |event|
        state = EasyActionState.find(event.to.to_s.gsub('state_', ''))

        Rails.logger.debug "StateMachine: EasyActionSequenceInstance.find(#{target.id}) - state EasyActionState.find(#{state.id}) \"#{state.name}\" is fired."

        target.update_columns(
            current_easy_action_state_id: state.id,
            status:                       :waiting)

        state.state_actions.each do |easy_action_state_action|
          FireEasyActionStateActionJob.perform_later(easy_action_state_action)
        end

        EasyActionSequenceInstanceEngineJob.perform_later(target)
      end

      @engine.restore!(@instance.current_state.ident)

      @engine
    end

    def next_transitions
      @next_transitions ||= EasyActionTransition.where(state_from: @instance.current_state).to_a
    end

    def trigger_transition(transition)
      result = engine.trigger(transition.ident)

      Rails.logger.debug "StateMachine: EasyActionSequenceInstance.find(#{@instance.id}) - triggered EasyActionTransition.find(#{transition.id}) \"#{transition.name}\" as #{result}."

      result
    end

  end
end
