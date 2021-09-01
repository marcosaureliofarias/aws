module EasyOrgChartQueryMixin
  def sql_for_field_with_supervisor(field, operator, value, db_table, db_field)
    subordinate_user_ids = []

    Array(value).each do |user_id|
      subordinate_user_ids |= EasyOrgChart::Tree.children_for(user_id.to_i)
    end

    if value.present? && subordinate_user_ids.empty?
      subordinate_user_ids = [0]
    end

    sql_for_field(field, operator, subordinate_user_ids, db_table, db_field)
  end
end
