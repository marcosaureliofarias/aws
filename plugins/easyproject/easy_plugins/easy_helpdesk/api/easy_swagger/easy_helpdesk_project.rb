module EasySwagger
  class EasyHelpdeskProject
    include EasySwagger::BaseModel
    swagger_me

    response_schema do
      property "project_id", type: "integer" do
        key :example, 172
        key :description, "Related project"
      end

      property "tracker_id", type: "integer" do
        key :example, 15
        key :description, "Related time tracker"
      end

      property "assigned_to_id", type: "integer" do
        key :example, 382
        key :description, "User whom project is assigned to"
      end

      property "monthly_hours", type: "number" do
        key :example, 6.2
        key :description, "Monthly hours"
        key :format, "float"
      end

      property "monitor_due_date", type: "boolean" do
        key :description, "Flag to enable due date monitoring"
      end

      property "monitor_spent_time", type: "boolean" do
        key :description, "Flag to enable spent time monitoring"
      end

      property "default_for_mailbox_id", type: "integer" do
        key :example, 2
        key :description, "Related mailbox"
      end

      property "watchers_ids", type: "array" do
        key :example, %w(5 12 37)
        key :description, "Ids of users who are members of the project"

        items do
          key :type, "string"
        end
      end

      property "email_header", type: "string" do
        key :example, "Dear Mr./Mrs."
        key :description, "Email header"
      end

      property "email_footer", type: "string" do
        key :example, "Kind Regards"
        key :description, "Email footer"
      end

      timestamps

      property "aggregated_hours", type: "boolean" do
        key :description, "Flag to enable aggregated hours"
      end

      property "aggregated_hours_remaining", type: "number" do
        key :example, 1.2
        key :description, "Remaining aggregated hours calculation"
        key :format, "float"
      end

      property "aggregated_hours_period", type: "string" do
        key :example, "quarterly"
        key :description, "Aggregated hours period"
      end

      property "aggregated_hours_start_date", type: "string" do
        key :example, "2014-01-01"
        key :format, "date"
        key :description, "Date aggregated hours to be calculated from"
      end

      property "aggregated_hours_last_reset", type: "string" do
        key :example, "2014-07-01"
        key :format, "date"
        key :description, "Date aggregated hours were last reset at"
      end

      property "aggregated_hours_last_update", type: "string" do
        key :example, "2014-07-06"
        key :format, "date"
        key :description, "Date aggregated hours were last updated at"
      end

      property "keyword", type: "string" do
        key :example, "urgent"
        key :description, "Keyword in project"
      end

      property "watcher_groups_ids", type: "array" do
        key :example, %w(35 41)
        key :description, "Ids of user groups who are members of the project"

        items do
          key :type, "string"
        end
      end

      property "automatically_issue_closer_enable", type: "boolean" do
        key :description, "Flag to enable automatic issue close rules"
      end

      property "issue_closers", type: "array", value: ->(context, project) { context&.render_auto_issue_closers(project) } do
        key :example, [1, 6, "7.3", 5, 6, "2.0"]
        key :description, "List of automatic issue close rules for the project"
      end
    end
  end
end
