# frozen_string_literal: true

module EasyGraphql
  module Mutations
    module Attributes
      class EasyShortUrlAttr < Attributes::BaseInput
        description 'Attributes for creating a short url'
        argument :source_url, String, required: true
        argument :valid_to, Types::Scalars::Date, required: false
        argument :allow_external, Boolean, required: false
      end
    end
  end
end
