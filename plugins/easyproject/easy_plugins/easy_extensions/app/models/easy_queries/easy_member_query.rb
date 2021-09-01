class EasyMemberQuery < EasyUserQuery

  def default_find_include
    [:members]
  end

  protected

  def get_class_name
    EasyUserQuery.name
  end

  def additional_statement
    unless @additional_statement_added
      @additional_statement = super.to_s
      @additional_statement << ' AND ' unless @additional_statement.blank?
      @additional_statement << "#{User.table_name}.status = #{Principal::STATUS_ACTIVE}"
      @additional_statement << " AND #{Member.table_name}.project_id = #{project_id}" if project_id
      @additional_statement_added = true
    end
    @additional_statement
  end

end
