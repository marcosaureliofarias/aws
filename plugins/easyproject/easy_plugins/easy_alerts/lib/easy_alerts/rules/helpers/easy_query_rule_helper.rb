module EasyAlerts
  module Rules
    module Helpers

      module EasyQueryRuleHelper

        def self.included(base)
          base.include(InstanceMethods)

          base.class_eval do

            attr_accessor :query_id, :entity_count

            validates :query_id, :presence => true
            validates_numericality_of :entity_count, :only_integer => true, :allow_nil => false

            def alert_query_rules_condition(entity_query, alert)
              operator = alert.rule_settings[:operator] || '>'
              case operator
              when '>'
                entity_query.entities if entity_query.entity_count > entity_count
              when '>='
                entity_query.entities if entity_query.entity_count >= entity_count
              when '='
                entity_query.entities if entity_query.entity_count == entity_count
              when '<='
                entity_query.entities if entity_query.entity_count <= entity_count
              when '<'
                entity_query.entities if entity_query.entity_count < entity_count
              end
            end

          end
        end

        module InstanceMethods

          def serialize_settings_to_hash(params)
            s = super
            s[:query_id] = params['query_id'].to_i unless params['query_id'].blank?
            s[:entity_count] = params['entity_count'].to_i unless params['entity_count'].blank?
            s[:operator] = params['operator'] unless params['operator'].blank?
            s
          end

          protected

          def initialize_properties(params)
            super
            @query_id = params[:query_id].to_i unless params[:query_id].blank?
            @entity_count = params[:entity_count].to_i unless params[:entity_count].blank?
          end

        end
        
      end

    end
  end
end
