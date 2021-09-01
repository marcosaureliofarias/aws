# frozen_string_literal: true

module EasyGraphql
  module Types
    class TimeEntry < Base
      description 'TimeEntry'

      field :id, ID, null: false
      field :project, Types::Project, null: true
      field :issue, Types::Issue, null: true
      field :user, Types::User, null: true
      field :hours, Float, null: true
      field :comments, String, null: true
      field :spent_on, Types::Scalars::Date, null: true
      field :easy_is_billable, Boolean, null: true

      field :editable, Boolean, null: false
      field :deletable, Boolean, null: false

      def editable
        object.editable_by?(::User.current)
      end

      def deletable
        object.editable_by?(::User.current)
      end

      def easy_is_billable
        ::Redmine::Plugin.installed?(:easy_budgetsheet) ? object.easy_is_billable : false
      end

    end
  end
end
