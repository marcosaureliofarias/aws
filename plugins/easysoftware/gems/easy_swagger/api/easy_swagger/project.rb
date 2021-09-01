module EasySwagger
  # describe Project model
  class Project
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do
      property "easy_external_id" do
        key :example, "external-system-1"
      end
      property "name" do
        key :example, "Blue 2"
      end
      property "homepage" do
        key :example, "blue-2"
      end
      property "description" do
        key :example, "I can’t abide these Jawas. Disgusting creatures."
      end

      relation *%w[parent], if: ->(_context, project) { project.parent && project.parent.visible? }
      relation *%w[author]

      %w[is_planned].each do |column|
        property column, type: "boolean"
      end
      property "easy_is_easy_template", type: "boolean" do
        key :description, "Is this project a template?"
      end

      %w[easy_start_date easy_due_date].each do |column|
        property column, format: "date", if: ->(_context, project) { !EasySetting.value('project_calculate_start_date', project) }
      end

      custom_fields
    end

    request_schema do
      key :required, %w[name author_id]
      property "easy_currency_code" do
        key :minLength, 3
        key :maxLength, 3
        key :example, "EUR"
      end
      property "easy_priority_id" do
        key :type, "object"
        key :readOnly, true
        property "id", type: "integer"
        property "name"
      end
    end

    project_statuses = %w[Project::STATUS_ACTIVE Project::STATUS_CLOSED Project::STATUS_ARCHIVED Project::STATUS_PLANNED Project::STATUS_DELETED]
    response_schema do
      property "status" do
        key :readOnly, true
        key :enum, project_statuses.map(&:constantize)
        key :example, "1"
        key :description, project_statuses.map { |i| "#{i.constantize} = #{i.split("_").last}" }.join("\n\n")
      end
      property "identifier" do
        key :readOnly, true
        key :example, "blue2"
      end
      property "sum_time_entries", type: "integer" do
        key :readOnly, true
      end
      property "sum_estimated_hours", type: "integer" do
        key :readOnly, true
      end
      property "currency" do
        key :readOnly, true
      end
      timestamps legacy: true
      %w[start_date due_date].each do |column|
        property column, format: "date"
      end

      property "trackers" do
        key :type, "array"
        key :description, "if you specify `include=trackers`"
        items do
          key :title, "Tracker"
          key :type, "object"
          key :readOnly, true
          property "id", type: "integer" do
            key :example, "1"
          end
          property "name" do
            key :example, "bug"
          end
          property "internal_name" do
            key :example, "easy_bug"
          end
          property "easy_external_id" do
            key :example, "easy_bug"
          end
        end
      end

      property "issue_categories" do
        key :type, "array"
        key :description, "if you specify `include=issue_categories`"
        items do
          key :title, "IssueCategory"
          key :type, "object"
          key :readOnly, true
          property "id", type: "integer"
          property "name"
        end
      end

      property "time_entry_activities" do
        key :type, "array"
        key :description, "if you specify `include=time_entry_activities`"
        items do
          key :title, "TimeEntryActivity"
          key :type, "object"
          key :readOnly, true
          property "id", type: "integer"
          property "name"
        end
      end

      property "enabled_modules" do
        key :type, "array"
        key :description, "if you specify `include=enabled_modules`"
        items do
          key :title, "EnabledModule"
          key :type, "object"
          key :readOnly, true
          property "id", type: "integer"
          property "name"
        end
      end

      property 'scheduled_for_destroy' do
        key :type, 'boolean'
        key :description, 'indicates if the project has been scheduled to be deleted'
        key :readOnly, true
      end

      property 'destroy_at' do
        key :type, 'string'
        key :format, 'date-time'
        key :description, 'the date when the project is expected to be deleted; is shown only if the project has been scheduled to be deleted'
        key :readOnly, true
      end

    end

  end
end
