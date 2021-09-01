class EasyMoneyTravelExpenseCustomField < CustomField
  def type_name; :easy_money_travel_expense_custom_field; end;

  def form_fields
    [:is_filter, :is_required]
  end

end
