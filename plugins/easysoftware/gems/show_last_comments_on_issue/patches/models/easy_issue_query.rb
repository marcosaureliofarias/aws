Rys::Patcher.add('EasyIssueQuery') do

  apply_if_plugins :easy_extensions

  instance_methods(feature: 'show_last_comments_on_issue.index') do

    def initialize_available_filters
      super

      on_filter_group(default_group_label) do
        add_available_filter 'has_comments', type: :boolean, label: :label_comment_plural
      end
    end

    def initialize_available_columns
      super
      group = l(:label_filter_group_easy_issue_query)
      add_available_column :last_comments, group: group
    end

  end

  instance_methods do

    def sql_for_has_comments_field(field, operator, value)
      sql = Journal.with_notes.non_system.where(journalized_type: 'Issue').select(:journalized_id).to_sql

      if value.first == '1'
        Issue.arel_table[:id].in(Arel.sql(sql)).to_sql
      else
        Issue.arel_table[:id].not_in(Arel.sql(sql)).to_sql
      end
    end

  end

end
