# frozen_string_literal: true

module EasyGraphql
  module Types
    class EasyChecklistItem < Base

      field :id, ID, null: false
      field :subject, String, null: false
      field :position, Int, null: false
      field :done, Boolean, null: true
      field :author, Types::User, null: false
      field :changed_by, Types::User, null: false
      field :last_done_change, GraphQL::Types::ISO8601DateTime, null: true
      field :created_at, GraphQL::Types::ISO8601DateTime, null: true
      field :updated_at, GraphQL::Types::ISO8601DateTime, null: true
      field :can_enable, Boolean, null: false
      field :can_disable, Boolean, null: false
      field :editable, GraphQL::Types::Boolean, null: false
      field :deletable, GraphQL::Types::Boolean, null: false

      def can_enable
        ::User.current.allowed_to?(:enable_easy_checklist_items, project)
      end

      def can_disable
        ::User.current.allowed_to?(:disable_easy_checklist_items, project)
      end

      def editable
        ::User.current.allowed_to?(:edit_easy_checklist_items, project)
      end

      def deletable
        ::User.current.allowed_to?(:delete_easy_checklist_items, project)
      end

      def project
        object.easy_checklist.entity&.project
      end

    end
  end
end
