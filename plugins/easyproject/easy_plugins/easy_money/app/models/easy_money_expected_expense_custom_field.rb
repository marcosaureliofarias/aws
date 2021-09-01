class EasyMoneyExpectedExpenseCustomField < CustomField
  def type_name; :easy_money_expected_expense_custom_field; end;

  def form_fields
    [:is_filter, :is_required]
  end

end
