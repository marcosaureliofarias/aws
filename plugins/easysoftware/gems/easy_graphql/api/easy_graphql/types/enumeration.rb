# frozen_string_literal: true

module EasyGraphql
  module Types
    class Enumeration < Base

      field :id, ID, null: false
      field :name, String, null: false
      field :position, Int, null: true
      field :is_default, Boolean, null: true
      field :type, String, null: true
      field :active, Boolean, null: true
      field :easy_color_scheme, String, null: true
      field :internal_name, String, null: true
      field :easy_external_id, String, null: true

    end
  end
end
