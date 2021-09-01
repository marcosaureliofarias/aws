# frozen_string_literal: true

module EasyGraphql
  module Types
    class Error < Base

      field :attribute, String, null: false
      field :full_messages, [String], null: false

    end
  end
end
