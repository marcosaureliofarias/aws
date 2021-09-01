module EasySwagger
  class EasySlaEvent
    include EasySwagger::BaseModel
    swagger_me

    response_schema do
      property "name", type: "string" do
        key :example, "weekly status update"
        key :description, "Event name"
      end

      property "occurence_time", type: "string" do
        key :example, "2020-10-27 09:00:00 UTC"
        key :format, "date-time"
        key :description, "Time of event occurrence"
      end

      property "issue_id", type: "integer" do
        key :example, 14
        key :description, "Related issue"
      end

      property "user_id", type: "integer" do
        key :example, 382
        key :description, "User who triggered event"
      end

      property "sla_response", type: "string" do
        key :example, "2020-10-27 09:02:36 UTC"
        key :format, "date-time"
        key :description, "Issue response time"
      end

      property "sla_resolve", type: "string" do
        key :example, "2020-10-28 15:23:06 UTC"
        key :format, "date-time"
        key :description, "Issue estimated resolve time"
      end

      property "first_response", type: "number" do
        key :example, 6.2
        key :description, "Delta of issue creation time and event creation time"
      end

      property "sla_response_fulfilment", type: "number" do
        key :example, 6.2
        key :description, "Time it took for issue to get a response"
      end

      property "sla_resolve_fulfilment", type: "number" do
        key :example, 6.2
        key :description, "Time it took for issue to be resolved"
      end

      property "project_id", type: "integer" do
        key :example, 172
        key :description, "Related project"
      end

      property "issue_status_id", type: "integer" do
        key :example, 12
        key :description, "Related issue status at time of event creation"
      end

      timestamps
    end
  end
end
