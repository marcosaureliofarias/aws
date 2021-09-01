require 'rys'

module EasyActions
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'easy_actions'

    initializer 'easy_actions.setup' do
      EasyActions::Actions.register 'EasyActions::Actions::ChangeIssueStatus'
      EasyActions::Actions.register 'EasyActions::Actions::CopyIssue'
      EasyActions::Actions.register 'EasyActions::Actions::NewEmail'
      EasyActions::Actions.register 'EasyActions::Actions::NewRocketChatMessage'

      EasyActions::Conditions.register 'EasyActions::Conditions::EasyGitCodeRequestCreated'
      EasyActions::Conditions.register 'EasyActions::Conditions::EasyGitCodeRequestMerged'
      EasyActions::Conditions.register 'EasyActions::Conditions::EasyGitCodeRequestClosed'
      EasyActions::Conditions.register 'EasyActions::Conditions::EasyGitTestFailed'
      EasyActions::Conditions.register 'EasyActions::Conditions::EasyGitTestPassed'
      EasyActions::Conditions.register 'EasyActions::Conditions::IssueSlaCreated'
      EasyActions::Conditions.register 'EasyActions::Conditions::IssueSlaExpiring'
    end
  end
end
