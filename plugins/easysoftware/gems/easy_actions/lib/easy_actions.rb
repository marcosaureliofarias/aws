require 'rys'

require 'easy/redmine'
require 'easy_actions/version'
require 'easy_actions/engine'

require 'finite_machine'
require 'easy_d3'
require 'easy_dagre_d3'

module EasyActions

  autoload :EasyActionCheckEntity, 'easy_actions/easy_action_check_entity'
  autoload :EasyActionEntity, 'easy_actions/easy_action_entity'
  autoload :EasyActionSequenceEntity, 'easy_actions/easy_action_sequence_entity'
  autoload :EasyActionSequenceInstanceEntity, 'easy_actions/easy_action_sequence_instance_entity'
  autoload :Model, 'easy_actions/model'
  autoload :StateMachine, 'easy_actions/state_machine'

  module Actions
    autoload :Base, 'easy_actions/actions/base'
    autoload :CallUrl, 'easy_actions/actions/call_url'
    autoload :ChangeIssueStatus, 'easy_actions/actions/change_issue_status'
    autoload :CopyIssue, 'easy_actions/actions/copy_issue'
    autoload :NewEmail, 'easy_actions/actions/new_email'
    autoload :NewRocketChatMessage, 'easy_actions/actions/new_rocket_chat_message'

    mattr_accessor :_registered

    def self.register(class_name)
      self._registered ||= []
      self._registered << class_name.to_s unless self._registered.include?(class_name.to_s)
    end

    def self.registered
      self._registered ||= []
      self._registered.map(&:safe_constantize).select(&:present?)
    end

  end

  module Conditions
    autoload :Base, 'easy_actions/conditions/base'
    autoload :EasyGitCodeRequestCreated, 'easy_actions/conditions/easy_git_code_request_created'
    autoload :EasyGitCodeRequestClosed, 'easy_actions/conditions/easy_git_code_request_closed'
    autoload :EasyGitCodeRequestMerged, 'easy_actions/conditions/easy_git_code_request_merged'
    autoload :EasyGitTestFailed, 'easy_actions/conditions/easy_git_test_failed'
    autoload :EasyGitTestPassed, 'easy_actions/conditions/easy_git_test_passed'
    autoload :IssueSlaCreated, 'easy_actions/conditions/issue_sla_created'
    autoload :IssueSlaExpiring, 'easy_actions/conditions/issue_sla_expiring'

    mattr_accessor :_registered

    def self.register(class_name)
      self._registered ||= []
      self._registered << class_name.to_s unless self._registered.include?(class_name.to_s)
    end

    def self.registered
      self._registered ||= []
      self._registered.map(&:safe_constantize).select(&:present?)
    end

  end

end
