# Redmine::MenuManager.map :admin_menu do |menu|
#   menu.push :easy_money_cashflow,
#             :easy_money_cashflows_path,
#             caption: :label_easy_money_cashflows,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

# Redmine::MenuManager.map :project_menu do |menu|
#   menu.push :easy_money_cashflow,
#             :easy_money_cashflows_path,
#             caption: :label_easy_money_cashflows,
#             param: :project_id,
#             html: { class: 'icon icon-invoice' },
#             if: proc { |p| User.current.admin? }
# end

Redmine::MenuManager.map :top_menu do |menu|
  menu.push(:label_easy_money_cash_flow, { controller: 'easy_money_cash_flow', action: :index },
      parent: :easy_money,
      caption: :label_easy_money_cash_flow,
      if: Proc.new { Rys::Feature.active?('easy_money_cashflow') && (User.current.allowed_to_globally?(:easy_money_cash_flow_history, {}) || User.current.allowed_to_globally?(:easy_money_cash_flow_prediction, {})) },
      html: { class: 'icon icon-cashflow' }
  )
end
