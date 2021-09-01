module EasyAlerts
  module Rules

    class IssueDueDate < EasyAlerts::Rules::DateBase

      def find_items(alert, user=nil)
        user ||= User.current

        scope = ::Issue.visible(user).joins(:status, :project)
        scope = scope.where(["#{IssueStatus.table_name}.is_closed = ?", false])
        scope = scope.where(["#{Project.table_name}.easy_is_easy_template = ?", false])
        scope = scope.where(["#{Issue.table_name}.author_id = ?", user.id]) if @where_iam_author == '1'
        scope = scope.where(["#{Issue.table_name}.assigned_to_id = ?", user.id]) if @where_iam_assignee == '1'
        scope = scope.alerts_active_projects if active_projects_only

        if alert.rule_settings[:date_type] == 'date'
          unless self.get_date == Date.today
            scope = scope.none
          end
        else
          scope = scope.where(["#{::Issue.table_name}.due_date = ?", self.get_date])
        end

        scope.to_a
      end

      def serialize_settings_to_hash(params)
        s = super
        s[:where_iam_author] = params['where_iam_author'] if !params['where_iam_author'].nil?
        s[:where_iam_assignee] = params['where_iam_assignee'] if !params['where_iam_assignee'].nil?
        s
      end

      def issue_provided?
        true
      end

      protected

      def initialize_properties(params)
        super
        @where_iam_author = params[:where_iam_author] if !params[:where_iam_author].nil?
        @where_iam_assignee = params[:where_iam_assignee] if !params[:where_iam_assignee].nil?
      end

    end

  end
end
