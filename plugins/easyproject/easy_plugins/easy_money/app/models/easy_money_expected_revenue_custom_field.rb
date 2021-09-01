class EasyMoneyExpectedRevenueCustomField < CustomField
  def type_name; :easy_money_expected_revenue_custom_field; end;

  def form_fields
    [:is_filter, :is_required]
  end

end
