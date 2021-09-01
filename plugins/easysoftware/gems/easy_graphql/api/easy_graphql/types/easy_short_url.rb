# frozen_string_literal: true

module EasyGraphql
  module Types
    class EasyShortUrl < Base
      description 'EasyShortUrl'

      self.entity_class = 'EasyShortUrl'

      field :id, ID, null: false
      field :shortcut, String, null: false
      field :short_url, String, null: false
      field :source_url, String, null: false
      field :valid_to, Types::Scalars::Date, null: true
      field :entity_id, Integer, null: false
      field :entity_type, String, null: false
      field :allow_external, Boolean, null: false

      def short_url
        "#{::Setting.protocol}://#{::Setting.host_name}#{Rails.application.routes.url_helpers.easy_shortcut_path(object.shortcut)}"
      end

    end
  end
end
