module EasyAlerts
  module Rules
    module Helpers

      module HelpdeskMonitorRuleHelper

        def self.included(base)
          base.include(InstanceMethods)

          base.class_eval do
            attr_accessor :percentage

            validates :percentage, presence: true
            validates_numericality_of :percentage, only_integer: true, allow_nil: false
          end
        end

        module InstanceMethods
    
          def serialize_settings_to_hash(params)
            s = super
            s[:percentage] = params['percentage'] if !params['percentage'].nil?
            s
          end
    
          protected
    
          def initialize_properties(params)
            super
            @percentage = params[:percentage] unless params[:percentage].blank?
          end

        end
      end

    end
  end
end
