module EasySwagger
  class Journal
    include EasySwagger::BaseModel
    swagger_me

    response_schema "Journal" do
      key :title, "Journal"
      key :type, "object"
      key :readOnly, true
      property "id", type: "integer"
      property "user", type: "object" do
        property "id", type: "integer"
        property "name"
      end
      property "notes"
      property "created_on", format: "date-time"
      property "private_notes", type: "boolean"
      property "details" do
        key :type, "array"
        key :xml, wrapped: true
        items do
          key :title, "JournalDetail"
          key :type, "object"
          property "property"
          property "name"
          property "old_value"
          property "new_value"
        end
      end

    end

  end
end