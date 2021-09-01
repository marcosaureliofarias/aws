class EasyMoneyTravelCostsController < EasyMoneyBaseItemsController

  menu_item :easy_money

  before_action :check_entity_enabled, :except => [:index]

  def inline_edit
    render_404
  end

  def inline_update
    render_404
  end

  private

  def easy_money_entity_class
    EasyMoneyTravelCost
  end

  def easy_money_entity_relation
    'travel_costs'
  end

  def easy_money_query
    EasyMoneyTravelCostQuery
  end

  def check_entity_enabled
    render_403 unless @project && @project.easy_money_settings.use_travel_costs?
  end

end
