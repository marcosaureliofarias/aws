module EasyMoney
  module EasyCrmCasePatch

    def self.included(base)
      base.class_eval do
        acts_as_easy_money

        def easy_money(easy_currency_code = nil)
          @easy_money ||= EasyMoneyEasyCrmCase.new(self, easy_currency_code || currency) if project.module_enabled?(:easy_crm)
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyCrmCase', 'EasyMoney::EasyCrmCasePatch', :if => Proc.new{Redmine::Plugin.installed?(:easy_crm)}
