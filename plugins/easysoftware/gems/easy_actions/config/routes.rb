Rails.application.routes.draw do

  rys_feature 'easy_actions' do

    resources :easy_action_check_templates
    resources :easy_action_checks do
      member do
        post 'passed'
        post 'failed'
      end
    end
    resources :easy_action_sequence_categories

    resources :easy_action_sequence_templates do
      collection do
        get 'autocomplete'
        get 'modal_index'
      end

      resources :easy_action_states, path: 'states' do
        collection do
          get 'autocomplete'
        end
      end

      resources :easy_action_state_actions, path: 'actions'

      resources :easy_action_transitions, path: 'transitions' do
        collection do
          get 'autocomplete'
        end
      end
    end

    resources :easy_action_sequences

    resources :easy_action_sequence_instances do
      member do
        get 'chart'
        post 'check_state'
      end
    end

  end
end
