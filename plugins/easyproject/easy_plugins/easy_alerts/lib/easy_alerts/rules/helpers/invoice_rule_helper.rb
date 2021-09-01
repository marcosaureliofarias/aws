module EasyAlerts
  module Rules
    module Helpers

      module InvoiceRuleHelper

        def self.included(base)
          base.include(InstanceMethods)

          base.class_eval do

            attr_accessor :projects

          end
        end

        module InstanceMethods

          def serialize_settings_to_hash(params)
            s = super
            s[:projects] = params['projects'] unless params['projects'].blank?
            s
          end

          protected

          def initialize_properties(params)
            super
            @projects = params[:projects] unless params[:projects].nil?
          end

        end
      end

    end
  end
end
