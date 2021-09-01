class EasyMoneyTravelCostCustomField < CustomField
  def type_name; :easy_money_travel_cost_custom_field; end;

  def form_fields
    [:is_filter, :is_required]
  end

end
