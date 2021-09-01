module EasyAlerts
  module Rules
    module Helpers

      module IssueRuleHelper

        def self.included(base)
          base.include(InstanceMethods)

          base.class_eval do
            
            attr_accessor :issue_ids, :project_id

            validates :issue_ids, :presence => true

          end
        end

        module InstanceMethods

          def serialize_settings_to_hash(params)
            s = super
            s[:issue_ids] = params['issue_ids'] unless params['issue_ids'].nil?
            s[:project_id] = params['project_id'].to_i unless params['project_id'].nil?
            s
          end

          protected

          def initialize_properties(params)
            super
            @issue_ids = params[:issue_ids] unless params[:issue_ids].nil?
            @project_id = params[:project_id].to_i unless params[:project_id].nil?
          end

        end
      end

    end
  end
end
