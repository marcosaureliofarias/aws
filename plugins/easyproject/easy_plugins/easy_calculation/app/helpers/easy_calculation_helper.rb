module EasyCalculationHelper
  include EasyExtensions::EasyAttributeFormatter

  def format_easy_calculation_price(price, project)
    if Redmine::Plugin.installed?(:easy_money)
      format_easy_money_price(price, project, precision: 2)
    else
      format_price(price, nil, precision: 2)
    end
  end
end
