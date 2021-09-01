# frozen_string_literal: true

module EasyGraphql
  module Types
    class Tag < Base
      description 'Tag'

      field :id, ID, null: false
      field :name, String, null: false

    end
  end
end
