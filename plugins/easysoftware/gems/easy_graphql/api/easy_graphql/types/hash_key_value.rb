# frozen_string_literal: true

module EasyGraphql
  module Types
    class HashKeyValue < Base

      field :key, String, null: false, hash_key: 'key'
      field :value, String, null: true, hash_key: 'value'

    end
  end
end
