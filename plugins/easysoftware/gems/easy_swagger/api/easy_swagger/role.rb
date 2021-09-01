module EasySwagger
  class Role
    include EasySwagger::BaseModel
    swagger_me

    shared_scheme do

      # property "name", type: "string" do
      #   key :example, 'Director (C-level) role'
      #   key :description, "Name"
      # end
      #
      # property "position", type: "integer" do
      #   key :example, '1'
      #   key :description, "Priority of role - just position in list"
      # end
      #
      # property "assignable", type: "boolean" do
      #   key :description, "Tasks can be assigned to this role"
      # end
      #
      # property "permissions", type: "array" do
      #   items do
      #     key :type, "string"
      #   end
      #   key :example, [:add_project, :edit_own_projects]
      # end
      #
      # property "issues_visibility", type: "string" do
      #   key :example, 'all'
      #   key :enum, ::Role::ISSUES_VISIBILITY_OPTIONS.map(&:first)
      #   key :description, "Tasks visibility"
      # end
      #
      # property "users_visibility", type: "string" do
      #   key :example, 'all'
      #   key :enum, ::Role::USERS_VISIBILITY_OPTIONS.map(&:first)
      #   key :description, "Users visibility"
      # end
      #
      # property "time_entries_visibility", type: "string" do
      #   key :example, 'all'
      #   key :enum, ::Role::TIME_ENTRIES_VISIBILITY_OPTIONS.map(&:first)
      #   key :description, "Spent time visibility"
      # end
      #
      # property "all_roles_managed", type: "boolean" do
      #   key :description, ""
      # end
      #
      # property "limit_assignable_users", type: "boolean" do
      #   key :description, "Tasks can be reassigned only to author"
      # end
      #
      # property "easy_external_id", type: "string" do
      #   key :description, ""
      # end
      #
      # property "description", type: "string" do
      #   key :example, 'C-level managers, heads of departments'
      #   key :description, "Description"
      # end
      #
      # property "easy_contacts_visibility", type: "string" do
      #   key :example, 'all'
      #   key :enum, ::Role::EASY_CONTACTS_VISIBILITY_OPTIONS.map(&:first)
      #   key :description, "Contacts visibility"
      # end
      #
      # property "easy_crm_cases_visibility", type: "string" do
      #   key :example, 'all'
      #   key :enum, ::Role::EASY_CRM_CASES_VISIBILITY_OPTIONS.map(&:first)
      #   key :description, "CRM cases visibility"
      # end
    end

    request_schema do
      # key :required, %w[project_id user_id hours spent_on]
    end

    response_schema do
      property "name", type: "string" do
        key :example, 'Director (C-level) role'
        key :description, "Name"
      end

      property "assignable", type: "boolean" do
        key :description, "Tasks can be assigned to this role"
      end

      property "permissions", type: "array" do
        items do
          key :type, "string"
        end
        key :example, [:add_project, :edit_own_projects]
      end

      property "issues_visibility", type: "string" do
        key :example, 'all'
        key :enum, ::Role::ISSUES_VISIBILITY_OPTIONS.map(&:first)
        key :description, "Tasks visibility"
      end

      property "users_visibility", type: "string" do
        key :example, 'all'
        key :enum, ::Role::USERS_VISIBILITY_OPTIONS.map(&:first)
        key :description, "Users visibility"
      end

      property "time_entries_visibility", type: "string" do
        key :example, 'all'
        key :enum, ::Role::TIME_ENTRIES_VISIBILITY_OPTIONS.map(&:first)
        key :description, "Spent time visibility"
      end
      #
      # property "builtin", type: "integer" do
      #   key :example, '0'
      #   key :readOnly, true
      # end
      #
      # property "settings", type: "object" do
      #   key :example, '{"permissions_all_trackers"=>{"view_issues"=>"1", "add_issues"=>"1", "edit_issues"=>"1", "add_issue_notes"=>"1", "delete_issues"=>"1"}, "permissions_tracker_ids"=>{"view_issues"=>[], "add_issues"=>[], "edit_issues"=>[], "add_issue_notes"=>[], "delete_issues"=>[]}}'
      #   key :readOnly, true
      # end
      #
      # property "easy_printable_templates_visibility", type: "string" do
      #   key :example, 'all'
      #   key :readOnly, true
      # end
      #
      # property "easy_risks_visibility", type: "string" do
      #   key :example, 'all'
      #   key :readOnly, true
      # end
      # timestamps legacy: false
    end

  end
end