module EasySwagger
  # describe Issue model
  class Issue
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do
      property "easy_external_id" do
        key :example, "external-system-1"
      end
      property "subject" do
        key :example, "Blue 2"
      end
      property "description" do
        key :example, "I can’t abide these Jawas. Disgusting creatures."
      end
      property "estimated_hours"

      property "done_ratio" do
        key :type, "integer"
        key :description, "step=10"
      end

      relation *%w[project tracker status priority activity category fixed_version parent author]

      %w[is_private is_favorited].each do |column|
        property column, type: "boolean"
      end

      %w[easy_email_to easy_email_cc].each do |column|
        property column, type: "string"
      end

      %w[start_date due_date].each do |column|
        property column, format: "date"
      end

      custom_fields
    end

    request_schema do
      key :required, %w[subject project_id tracker_id status_id priority_id author_id]
    end

    response_schema do
      property "css_classes" do
        key :readOnly, true
        key :example, "issue tracker-7 status-13 priority-18 priority-highest"
      end
      property "total_estimated_hours" do
        key :readOnly, true
      end
      timestamps legacy: true
      property "closed_on", type: "string", format: "date-time"

      attachments

      property "relations" do
        key :type, "array"
        key :description, "if you specify `include=relations`"
        key :xml, wrapped: true
        items do
          key :title, "Relation"
          key :type, "object"
          key :readOnly, true
          property "id", type: "integer" do
            key :example, "1"
          end
          property "issue_id", type: "integer" do
            key :example, "3"
          end
          property "issue_to_id", type: "integer" do
            key :example, "5"
          end
          property "relation_type" do
            key :example, "precedes"
            key :enum, ::IssueRelation::TYPES.keys
          end
          property "delay", type: "integer" do
            key :description, "value in days"
            key :example, "5"
          end
        end
      end

      property "changesets" do
        key :type, "array"
        key :description, "if you specify `include=changesets`"
        key :xml, wrapped: true
        items do
          key :title, "Changeset"
          key :type, "object"
          key :readOnly, true
          property "user", type: "object" do
            property "id", type: "integer"
            property "name"
          end
          property "comments"
          property "committed_on", format: "date-time"
        end
      end

      journals

      property "watchers", if: ->(_context, issue) { ::User.current.allowed_to?(:view_issue_watchers, issue.project) } do
        key :type, "array"
        key :description, "if you specify `include=watchers`"
        key :xml, wrapped: true
        items do
          key :title, "Watcher"
          key :type, "object"
          key :readOnly, true
          property "user", type: "object" do
            property "id", type: "integer"
            property "name"
          end
        end
      end

    end

  end
end
