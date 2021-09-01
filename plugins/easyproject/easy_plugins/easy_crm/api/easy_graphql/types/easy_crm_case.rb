# frozen_string_literal: true

module EasyGraphql
  module Types
    class EasyCrmCase < Base

      field :id, ID, null: false
      field :name, String, null: false
      field :easy_crm_case_path, String, null: true

      def easy_crm_case_path
        Rails.application.routes.url_helpers.easy_crm_case_path(object)
      end

    end
  end
end

