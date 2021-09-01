# frozen_string_literal: true

module EasyGraphql
  module Types
    class Journal < Base

      self.entity_class = 'Journal'

      field :id, ID, null: false
      field :user, Types::User, null: true
      field :created_on, GraphQL::Types::ISO8601DateTime, null: true
      field :details, [Types::JournalDetail], null: true, method: :visible_details

      field :notes, String, null: true do
        argument :formatted, Boolean,
                 'Format notes based on configured text editor',
                 default_value: false,
                 required: false
      end

      field :editable, Boolean, null: false
      field :deletable, Boolean, null: false
      field :private_notes, Boolean, null: false

      def notes(formatted:)
        if formatted
          cleared_issues_helpers.textilizable(object, :notes)
        else
          object.notes
        end
      end

      def editable
        object.editable_by?(::User.current)
      end

      def deletable
        object.editable_by?(::User.current)
      end

    end
  end
end
