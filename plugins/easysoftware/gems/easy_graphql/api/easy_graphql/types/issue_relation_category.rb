# frozen_string_literal: true

module EasyGraphql
  module Types
    class IssueRelationCategory < Base

      field :name, String, null: false, hash_key: 'name'
      field :key, String, null: false, hash_key: 'key'

    end
  end
end
