module EasyAgileBoard
  module IssuesControllerPatch

    def self.included(base)
      base.class_eval do

        prepend_before_action -> { params['issue'].delete('easy_sprint_id') }, only: :create, if: -> { params['issue'] && params['issue']['target_backlog'] == 'project_backlog' }

      end
    end

    module InstanceMethods

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'IssuesController', 'EasyAgileBoard::IssuesControllerPatch'
