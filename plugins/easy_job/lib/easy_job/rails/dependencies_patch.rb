module EasyJob
  ##
  # ActiveSupport::Dependencies
  #
  # 1. Cannot use prepend - its a Module
  # 2. Cannot use Mutex because of deadlock
  #
  module DependenciesPatch

    def self.included(base)
      base.class_eval do

        def load_missing_constant_with_easy_job(from_mod, const_name)
          load_missing_constant_without_easy_job(from_mod, const_name)
        rescue => e
          if Thread.current[:easy_job] && e.message.start_with?('Circular dependency detected')
            # Easy job crashed on circular dependecy maybe because different jobs want the same constant
            # Lets wait a while :-)
            sleep 1

            if from_mod.const_defined?(const_name, false)
              # Problem solved
              return from_mod.const_get(const_name)
            end
          end

          # Waiting was too short or there is actual circular dependecy
          raise
        end

        alias_method_chain :load_missing_constant, :easy_job
      end
    end

  end
end

if Rails.version < '5'
  ActiveSupport::Dependencies.include(EasyJob::DependenciesPatch)
end
