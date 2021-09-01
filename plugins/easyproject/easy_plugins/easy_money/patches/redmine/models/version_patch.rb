module EasyMoney
  module VersionPatch

    def self.included(base)
      base.class_eval do
        has_many :time_entries, :through => :fixed_issues
        acts_as_easy_money

        def easy_money(easy_currency_code = nil)
          @easy_money ||= EasyMoneyVersion.new(self, easy_currency_code || project.easy_currency_code) if project.module_enabled?(:easy_money)
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'Version', 'EasyMoney::VersionPatch'
