module EasyAlerts
  module Rules
    module Helpers

      module VersionRuleHelper

        def self.included(base)
          base.include(InstanceMethods)

          base.class_eval do

            attr_accessor :version_ids
            
            validates :version_ids, :presence => true
            
          end
        end

        module InstanceMethods

          def serialize_settings_to_hash(params)
            s = super
            s[:version_ids] = params['version_ids'] if !params['version_ids'].nil?
            s
          end

          protected
          
          def initialize_properties(params)
            super
            @version_ids = params[:version_ids] unless params[:version_ids].blank?
          end

        end
      end

    end
  end
end
