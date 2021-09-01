# frozen_string_literal: true

module EasyGraphql
  module Types
    class EasyContact < Base

      field :id, ID, null: false
      field :firstname, String, null: true
      field :lastname, String, null: true
      field :name, String, null: true
      field :easy_contact_path, String, null: true
      
      def easy_contact_path
        Rails.application.routes.url_helpers.easy_contact_path(object)
      end

    end
  end
end
