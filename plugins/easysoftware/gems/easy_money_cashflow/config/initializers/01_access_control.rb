if Redmine::Plugin.installed?(:easy_money)
  Redmine::AccessControl.map do |map|
    map.project_module :easy_money do |pmap|
      map.rys_feature('easy_money_cashflow') do |fmap|
        fmap.permission :easy_money_cash_flow_prediction, {
            easy_money_cash_flow: [:index] },
                        global: true,
                        read: true
        fmap.permission :easy_money_cash_flow_history, {
            easy_money_cash_flow: [:index] },
                        global: true,
                        read: true
      end
    end
  end
end
