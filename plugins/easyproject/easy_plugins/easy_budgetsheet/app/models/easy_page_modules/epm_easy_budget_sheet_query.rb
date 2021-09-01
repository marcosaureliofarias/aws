class EpmEasyBudgetSheetQuery < EpmEasyQueryBase

  def category_name
    @category_name ||= 'others'
  end

  def runtime_permissions(user)
    user.allowed_to_globally?(:view_budgetsheet, {})
  end

  def query_class
    EasyBudgetSheetQuery
  end

end
