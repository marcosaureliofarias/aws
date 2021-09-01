class AddMySubordinatesToUsersFilter
  def self.call(filters, filter_name)
    if filters[filter_name]
      users_values = filters[filter_name][:values]

      filters[filter_name][:values] = Proc.new do
        values = users_values.kind_of?(Proc) ? users_values.call : users_values

        AddMySubordinatesToUsersList.call(values)
      end
    end
  end
end
