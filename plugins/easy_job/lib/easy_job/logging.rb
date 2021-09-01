module EasyJob
  module Logging

    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end

    module InstanceMethods

      def log_info(message)
        message = "#{job_name}:#{job_id} - #{message}"
        EasyJob.logger.info(message)
      end

      def log_warn(message)
        message = "#{job_name}:#{job_id} - #{message}"
        EasyJob.logger.warn(message)
      end

      def log_error(message)
        message = "#{job_name}:#{job_id} - #{message}"
        EasyJob.logger.error(message)
      end

    end

    module ClassMethods

      def log_info(message)
        message = "#{job_name} - #{message}"
        EasyJob.logger.info(message)
      end

      def log_warn(message)
        message = "#{job_name} - #{message}"
        EasyJob.logger.warn(message)
      end

      def log_error(message)
        message = "#{job_name} - #{message}"
        EasyJob.logger.error(message)
      end

    end

  end
end
