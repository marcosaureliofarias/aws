module EasyGraphql
  module Mutations
    class EasyShortUrlCreate < Base
      description 'Create an short url.'

      argument :entity_id, ID, required: true
      argument :entity_type, String, required: true
      argument :attributes, EasyGraphql::Mutations::Attributes::EasyShortUrlAttr, required: true

      field :easy_short_url, EasyGraphql::Types::EasyShortUrl, null: true
      field :errors, [String], null: true

      def resolve(entity_id:, entity_type:, attributes:)
        return response(errors: [::I18n.t('easy_graphql.record_not_found')]) unless find_entity(entity_id, entity_type)

        prepare_short_url(attributes)
        if @short_url.save
          response(easy_short_url: @short_url)
        else
          response(errors: @short_url.errors.full_messages)
        end
      end

      private

      def prepare_short_url(attributes)
        @short_url = ::EasyShortUrl.new(entity: @entity)
        @short_url.safe_attributes = attributes.to_hash
      end

      def response(easy_short_url: nil, errors: [])
        { easy_short_url: easy_short_url, errors: errors }
      end
    end
  end
end
