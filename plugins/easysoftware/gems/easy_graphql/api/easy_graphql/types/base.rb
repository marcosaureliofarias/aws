# frozen_string_literal: true

module EasyGraphql
  module Types
    class Base < GraphQL::Schema::Object
      field_class Fields::Base

      # Set entity_class to use loads for arguments
      # example:
      # self.entity_class = 'Entity'
      # argument :entity_id, ID, loads: Types::Entity
      class_attribute :entity_class
      self.entity_class = nil

      def self.has_custom_values
        field :custom_values, [Types::CustomValue], null: true, method: :visible_custom_field_values
      end

      def self.has_journals
        field :journals, [Types::Journal], null: true
      end

      # Based on {ActionController::Helpers::ClassMethods.helpers}
      # With reouting additionals
      # def self.issues_helpers
      #   @issues_helpers ||= begin
      #     proxy = ActionView::Base.new
      #     proxy.config = IssuesController.config.inheritable_copy
      #     proxy.extend(IssuesController._helpers)
      #     proxy.extend(Rails.application.routes.url_helpers)
      #
      #     def proxy.url_options
      #       ::Mailer.default_url_options
      #     end
      #
      #     proxy
      #   end
      # end

      # Helpers is caching an instance methods
      # In normal view - the cache is cleared every request
      # but this is not
      # TODO: using a {issue_controller.view_context}
      def cleared_issues_helpers
        helpers = issue_controller.helpers
        helpers.instance_variable_set(:@cached_names, nil)
        helpers.instance_variable_set(:@journal_detail_issue_scope, nil)
        helpers
      end

      def issue_controller
        context[:_issue_controller] ||= begin
          request = ActionDispatch::Request.new({})
          request.routes = IssuesController._routes
          request.set_header('rack.input', '')

          instance = IssuesController.new
          instance.instance_variable_set(:@default_url_options, Mailer.default_url_options)
          instance.set_request! request
          instance.set_response! IssuesController.make_response!(request)
          instance.params = {}
          instance
        end
      end

    end
  end
end
