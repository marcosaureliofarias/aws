module EasySwagger
  class TimeEntry
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do
      relation *%w[project issue user priority activity]
      property "easy_external_id"
      property "hours" do
        key :example, "8"
        key :description, "Amount of spent hours"
      end
      property "spent_on", format: "date" do
        key :example, "2019-07-09"
        key :description, "Date of spent time. It can be limited by global setting"
      end
      property "comments" do
        key :example, "I work very hard"
      end
      %w[easy_is_billable easy_billed].each do |column|
        property column, type: "boolean"
      end

      custom_fields
    end

    request_schema do
      key :required, %w[project_id user_id hours spent_on]
    end

    response_schema do
      timestamps legacy: true
    end

  end
end