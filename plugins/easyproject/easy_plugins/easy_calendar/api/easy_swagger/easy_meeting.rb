module EasySwagger
  class EasyMeeting
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do

      property "name", type: "string" do
        key :example, 'weekly status update'
        key :description, "Name"
      end

      property "description"

      property "all_day", type: "boolean" do
        key :description, "All day"
      end

      property "start_time", type: "string" do
        key :example, '2020-10-27 09:00:00 UTC'
        key :format, "date-time"
        key :description, "Start"
      end

      property "end_time", type: "string" do
        key :example, '2020-10-27 11:00:00 UTC'
        key :format, "date-time"
        key :description, "End"
      end

      property "mails", type: "array" do
        items do
          key :format, "email"
        end
        key :description, "E-mail addresses"
      end

      relation *%w[project easy_room]

      property "easy_is_repeating", type: "boolean" do
        key :description, "Repeating"
      end

      property "easy_next_start", type: "string" do
        key :format, "date"
        key :description, "Next repetition"
      end

      property "place_name", type: "string" do
        key :description, "Place"
      end

      property "uid", type: "string" do
        key :example, '1919385b-5040-46e7-93e5-addbab6b39fa'
        key :format, "uuid"
      end

      property "priority", type: "integer" do
        key :example, 'normal'
        key :enum, ::EasyMeeting.priorities.keys
        key :description, "Priority"
      end

      property "privacy", type: "integer" do
        key :example, 'xpublic'
        key :enum, ::EasyMeeting.privacies.keys
        key :description, "Privacy"
      end

      property "big_recurring", type: "boolean" do
        key :description, "Big recurring"
      end

      property "easy_resource_dont_allocate", type: "boolean" do
        key :description, ""
      end

      property "email_notifications", type: "integer" do
        key :example, 'right_now'
        key :description, ""
      end
    end

    request_schema do
      # key :required, %w[project_id user_id hours spent_on]

      easy_repeat_options
    end

    response_schema do

      relation *%w[author]

      property "user_ids", type: "array" do
        items do
          key :type, "integer"
        end
      end


      timestamps legacy: false
    end

  end
end