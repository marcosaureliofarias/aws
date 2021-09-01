# This file define all features
#
# Rys::Feature.for_plugin(EasyMoneyCashflow::Engine) do
#   Rys::Feature.add('easy_money_cashflow.project.show')
#   Rys::Feature.add('easy_money_cashflow.issue.show')
#   Rys::Feature.add('easy_money_cashflow.time_entries.show')
# end

Rys::Feature.for_plugin(EasyMoneyCashflow::Engine) do
  Rys::Feature.add('easy_money_cashflow') do
    Redmine::Plugin.installed?(:easy_money) && RysFeatureRecord.active?('easy_money_cashflow')
  end
end
