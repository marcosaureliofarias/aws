# frozen_string_literal: true

module EasyGraphql
  module Types
    class Project < Base

      field :id, ID, null: false
      field :identifier, String, null: true
      field :name, String, null: true
      field :author, Types::User, null: true
      field :start_date, Types::Scalars::Date, null: true
      field :due_date, Types::Scalars::Date, null: true
      field :created_on, GraphQL::Types::ISO8601DateTime, null: true
      field :updated_on, GraphQL::Types::ISO8601DateTime, null: true
      field :trackers, [Types::Tracker], null: true
      field :activities_per_role, [Types::Enumeration], null: true
      field :users, [Types::User], null: true
      field :enabled_module_names, [String], null: false
      field :descendants, [Types::Project], null: true
      field :enabled_features, resolver: EasyGraphql::Resolvers::EnabledFeatures

      field :journals, [Types::Journal], null: true do
        argument :all, Boolean, required: false
      end
      field :total_estimated_hours, Float, null: true
      field :total_spent_hours, Float, null: true

      field :description, String, null: true do
        argument :formatted, Boolean,
                 'Format description based on configured text editor',
                 default_value: false,
                 required: false
      end

      def enabled_module_names
        object.enabled_module_names & Redmine::AccessControl.available_project_modules.map(&:to_s)
      end

      def description(formatted:)
        if formatted
          cleared_issues_helpers.textilizable(object, :description)
        else
          object.description
        end
      end

      def descendants
        object.descendants.visible
      end

      def total_estimated_hours
        object.sum_of_issues_estimated_hours
      end

      def total_spent_hours
        ::TimeEntry.sum_total_spent_hours(object)
      end

      def journals(all: nil)
        journals = object.journals.preload(:user, :details).reorder(id: :desc)

        if !all
          limit = EasySetting.value('easy_extensions_journal_history_limit')
          journals = journals.limit(limit)
        end

        journals = journals.to_a
        journals.reject!(&:private_notes?) if !::User.current.allowed_to?(:view_private_notes, object)
        journals
      end

    end
  end
end
