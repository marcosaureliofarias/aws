# frozen_string_literal: true

module EasyGraphql
  module Types
    class Locale < Base

      Entity = Struct.new(:key, :translation)

      field :key, String, null: false
      field :translation, String, null: false

    end
  end
end
