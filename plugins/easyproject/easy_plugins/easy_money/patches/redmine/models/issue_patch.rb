module EasyMoney
  module IssuePatch

    def self.included(base)
      base.class_eval do
        acts_as_easy_money

        def easy_money(easy_currency_code = nil)
          @easy_money ||= EasyMoneyIssue.new(self, easy_currency_code || project.easy_currency_code) if project.module_enabled?(:easy_money)
        end

        def easy_money_enabled?
          @easy_money_enabled ||= (EasyMoneySettings.find_settings_by_name(:use_easy_money_for_issues, self.project) == '1')
        end

        def easy_money_visible?(user=User.current)
          self.project.easy_money_visible?(user)
        end

        def easy_money_editable?(user=User.current)
          self.project.easy_money_editable?(user)
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_model_patch 'Issue', 'EasyMoney::IssuePatch'
