module EasyRedmine
  module Menus
    Redmine::MenuManager.map :top_menu do |menu|
      children = menu.menu_items.children
      order = %i[
        easy_gantt_resources
        easy_gantt
        easy_money
        easy_budgetsheet
        easy_attendances
        test_cases
        easy_crm
        easy_contacts
      ] | children.map(&:name)
      children.sort_by! { |item| order.index(item.name) }
    end
  end
end
