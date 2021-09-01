module EasyAlerts
  module Rules
    module Helpers

      module DateRuleHelper

        def self.included(base)
          base.include(InstanceMethods)

          base.class_eval do

            attr_accessor :date_type, :delta, :date

            validates :delta, :presence => true, :if => Proc.new { |o| o.date_type == 'delta' || o.date_type.nil? }
            validates :date, :presence => true, :if => Proc.new { |o| o.date_type == 'date' }
            validates_numericality_of :delta, :only_integer => true, :if => Proc.new { |o| o.date_type == 'delta' || o.date_type.nil? }
            
          end
        end

        module InstanceMethods

          def serialize_settings_to_hash(params)
            s = super
            s[:date_type] = params['date_type'] if !params['date_type'].nil?
            s[:delta] = params['delta'].to_i if !params['delta'].nil? && s[:date_type] == 'delta'
            s[:date] = begin; params['date'].to_date; rescue; end if !params['date'].nil? && s[:date_type] == 'date'
            s
          end

          protected
          
          def initialize_properties(params)
            super
            @date_type = params[:date_type] if !params[:date_type].nil?
            @delta = params[:delta].to_i if !params[:delta].nil? && self.date_type == 'delta'
            @date = begin; params[:date].to_date; rescue; end if !params[:date].nil? && self.date_type == 'date'
          end

          def get_date
            if (self.date_type == 'delta')
              (Date.today - self.delta.to_i)
            elsif (self.date_type == 'date')
              if self.date.is_a?(Date)
                self.date
              else
                begin; self.date.to_date; rescue; nil; end;
              end
            end
          end

        end
      end
      
    end
  end
end
