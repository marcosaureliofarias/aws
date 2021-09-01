Rys::Patcher.add('Project') do
  apply_if_plugins :easy_extensions

  instance_methods do
    def users_with_builtin_roles
      @users_with_builtin_roles ||= User.joins(:easy_user_type) \
                                        .merge(EasyUserType.where.not(builtin_role: nil)) \
                                        .includes(:easy_user_type) \
                                        .includes(easy_user_type: :builtin_role) \
                                        .joins(Project.sanitize_sql_array ["LEFT OUTER JOIN #{Member.table_name}" + \
                                                                           " ON #{Member.table_name}.user_id = #{User.table_name}.id" + \
                                                                           " AND #{Member.table_name}.project_id = ?", self.id]
                                              ) \
                                        .merge(Member.where(user: nil))
    end
  end

end