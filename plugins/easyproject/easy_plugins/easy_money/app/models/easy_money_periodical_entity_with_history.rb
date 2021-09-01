class EasyMoneyPeriodicalEntityWithHistory < EasyMoneyPeriodicalEntity

  def view_overview_item
    'easy_money_periodical_entities/easy_money_periodical_entity_with_history'
  end

  def current_price
    empei = self.easy_money_periodical_entity_items.until_period.first
    empei.nil? ? 0.0 : empei.price1
  end

  def total_price
    empei = self.easy_money_periodical_entity_items.sorted_by_period.first
    empei.nil? ? 0.0 : empei.price1
  end

  def price_until(date_period)
    empei = self.easy_money_periodical_entity_items.until_period(date_period).first
    empei.nil? ? 0.0 : empei.price1
  end

  def user_defined_items?
    false
  end

end
