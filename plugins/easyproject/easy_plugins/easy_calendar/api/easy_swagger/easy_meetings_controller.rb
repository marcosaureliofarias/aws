module EasySwagger
  class EasyMeetingsController

    include EasySwagger::BaseController
    swagger_me tag_name: "EasyCalendarMeeting"
    include Swagger::Blocks
    # ::EasySwagger.register name

    add_tag name: "EasyCalendarMeeting", description: "Easy Calendar API"
    remove_action action: :get

    base = self
    swagger_path "/easy_calendar/feed.json" do
      operation :get do
        key :summary, "List of Easy Meetings"
        key :tags, [base.tag_name]
        # extend EasySwagger::Parameters
        parameter do
          key :name, "start"
          key :required, true
          key :description, "get meetings only starts in this time"
          key :in, "query"
          schema type: "string" do
            key :description, "Can be string **today** or Time in %s format! Example for 2020-04-29 11:50:27 +02:00"
            key :example, "1588153643"
          end
        end
        parameter do
          key :name, "end"
          key :required, true
          key :description, "get meetings only ends in this time"
          key :in, "query"
          schema type: "string" do
            key :description, "Can be string **today** or Time in %s format! Example for 2020-04-29 11:50:27 +02:00"
            key :example, "1588153643"
          end
        end
        parameter do
          key :name, "enabled_calendars"
          key :description, "list of types - Meetings, Attendance, etc.... by default its `easy_meeting_calendar`"
          key :in, "query"
          schema type: "array" do
            items do
              key :type, "string"
              key :enum, EasyCalendar::AdvancedCalendar.allowed_registered_calendars.keys
              key :example, "easy_meeting_calendar"
            end
          end
        end
        response 200 do
          key :description, "ok"
          content "application/json" do
            schema type: "array" do
              items do
                key "$ref", "EasyCalendarMeeting"
              end
            end
          end
        end
        response 401 do
          key :description, 'not authorized'
        end
      end
    end

    swagger_component do
      schema "EasyCalendarMeeting" do
        key :description, "Response only for feed, which is something like list of meetings of User.current"
        property :id, type: "string" do
          key :example, "easy_meeting-296864"
          key :description, "id prefix include __model_name__"
        end
        property :eventType, type: "string" do
          key :example, "meeting_invitation"
        end
        property :url, type: "string" do
          key :example, "/easy_meetings/296864"
          key :description, "**RELATIVE** path to this meeting"
        end
        property :parentUrl, type: "string" do
          key :example, "/easy_meetings/296719"
          key :description, "**RELATIVE** path to parent meeting (if this is repeated)"
        end
        property :location, type: "string" do
          key :example, "Jednačka 2.p"
          key :description, "room name or just location of meeting"
        end
        property :title, type: "string" do
          key :example, "DevOps"
          key :description, "name of meeting"
        end
        property :start, type: "string" do
          key :example, "2020-04-29T09:00:00+02:00"
          key :format, "date-time"
        end
        property :end, type: "string" do
          key :example, "2020-04-29T11:00:00+02:00"
          key :format, "date-time"
        end
        property :allDay, type: "boolean" do
          key :description, "is this `all day` meeting ?"
        end
        property :color, type: "string" do
          key :example, "#daddf6"
          key :description, "internal use - color of meeting in `easy_calendar`"
        end
        property :borderColor, type: "string" do
          key :example, "#c3d0e5"
          key :description, "???"
        end
        %i[editable accepted declined].each do |bool|
          property bool, type: "boolean" do
            key :description, "is meeting #{bool}?"
          end
        end
        property :bigRecurringChildren, type: "boolean" do
          key :description, "Meeting is recurrent - this is repeated meeting of `parent`"
        end
      end

    end
  end
end