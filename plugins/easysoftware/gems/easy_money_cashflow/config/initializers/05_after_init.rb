if Redmine::Plugin.installed?(:easy_money)
  EasyExtensions::PatchManager.register_easy_page_controller 'EasyMoneyCashFlowController'
  EasyExtensions::ActionProposer.add({ controller: 'easy_money_cash_flow', action: 'index' })
end