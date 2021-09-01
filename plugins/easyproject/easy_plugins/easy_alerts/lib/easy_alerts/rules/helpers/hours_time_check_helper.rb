module EasyAlerts
  module Rules
    module Helpers

      module HoursTimeCheckHelper

        def self.included(base)
          base.include(InstanceMethods)

          base.class_eval do

            attr_accessor :hours_time_check

          end
        end

        module InstanceMethods

          def serialize_settings_to_hash(params)
            s = super
            s[:hours_time_check] = params['hours_time_check'] if !params['hours_time_check'].nil?
            s
          end

          def expires_at(alert)
            return nil if alert.nil? || alert.period_options.blank? || alert.period_options['time'] != 'defined'

            (Time.now + 1.day).at_beginning_of_day
          end

          protected

          def initialize_properties(params)
            super
            @hours_time_check = params[:hours_time_check] unless params[:hours_time_check].blank?
          end

        end

      end

    end
  end
end
