# frozen_string_literal: true

module EasyGraphql
  module Resolvers
    class EnabledFeatures < Resolvers::Base
      description 'Return a list of enabled features.'

      type [String], null: true

      attr_accessor :enabled_features

      def resolve
        self.enabled_features = []
        check_for_enabled
        enabled_features
      end

      private

      def check_for_enabled
        enabled_features << 'billable' if ::Redmine::Plugin.installed?(:easy_budgetsheet) && ::EasySetting.value('show_billable_things')
        enabled_features << 'issue_duration' if ::Rys::PluginsManagement.find(:issue_duration) && ::Rys::Feature.active?('issue_duration')
      end

    end
  end
end
