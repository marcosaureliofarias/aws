# frozen_string_literal: true

module EasyGraphql
  module Types
    class EasyRoom < Base

      field :id, ID, null: false
      field :name, String, null: false
      field :capacity, Int, null: true

    end
  end
end
