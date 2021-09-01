Rys::Patcher.add('EasyIssueQuery') do

  apply_if_plugins :easy_extensions

  instance_methods(feature: 'issue_duration') do

    def initialize_available_filters
      super
      on_filter_group(default_group_label) do
        add_available_filter 'easy_duration', { type: :integer }
      end
    end

    def initialize_available_columns
      super
      on_column_group(default_group_label) do
        add_available_column :easy_duration, sortable: "#{Issue.table_name}.easy_duration", sumable: :bottom
      end
    end

  end

end
