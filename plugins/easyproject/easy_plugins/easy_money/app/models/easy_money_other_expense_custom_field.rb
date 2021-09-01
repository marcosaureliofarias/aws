class EasyMoneyOtherExpenseCustomField < CustomField
  def type_name; :easy_money_other_expense_custom_field; end;

  def form_fields
    [:is_filter, :is_required]
  end

end
