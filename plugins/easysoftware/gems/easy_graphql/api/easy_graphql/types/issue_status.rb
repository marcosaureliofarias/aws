# frozen_string_literal: true

module EasyGraphql
  module Types
    class IssueStatus < Base

      field :id, ID, null: false
      field :name, String, null: false
      field :is_closed, Boolean, null: false

    end
  end
end
