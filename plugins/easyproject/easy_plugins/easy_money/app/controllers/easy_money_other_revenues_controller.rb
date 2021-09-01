class EasyMoneyOtherRevenuesController < EasyMoneyBaseItemsController

  menu_item :easy_money

  before_action :check_setting_revenues_type, :only => [:new, :create]

  def inline_update
    entity = @entity.other_revenues.first || @entity.other_revenues.new(:name => l(:label_easy_money_new_revenue_text), :description => l(:label_easy_money_new_revenue_description), :spent_on => Date.current)
    super(entity)
  end

  private

  def check_setting_revenues_type
    render_404 if @project && @project.easy_money_settings.revenues_type == 'sum' && @project.other_revenues.size > 0
  end

  def easy_money_entity_class
    EasyMoneyOtherRevenue
  end

  def easy_money_entity_relation
    'other_revenues'
  end

  def easy_money_query
    EasyMoneyOtherRevenueQuery
  end

end
