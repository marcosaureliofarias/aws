module EasyMoney
  module EasyCrmCasesControllerPatch

    def self.included(base)
      base.class_eval do
        helper :easy_money
        include EasyMoneyHelper
      end
    end
  end
end
EasyExtensions::PatchManager.register_controller_patch 'EasyCrmCasesController', 'EasyMoney::EasyCrmCasesControllerPatch', :if => Proc.new{Redmine::Plugin.installed?(:easy_crm)}
