# Hooks definitions
# http://www.redmine.org/projects/redmine/wiki/Hooks

module EasyMoneyCashflow
  class Hooks < ::Redmine::Hook::ViewListener
    render_on :view_easy_money_cash_flow_link, partial: 'easy_money/link_to_cash_flow'
  end
end
