module EasyPatch
  module ActionDispatchReloaderPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do
        alias_method_chain :call, :easy_extensions
      end
    end

    module InstanceMethods
      def call_with_easy_extensions(env)
        if env['REQUEST_PATH'].to_s.include?('assets/')
          backup_condition = @condition.dup
          begin
            @condition = lambda { false }
            call_without_easy_extensions(env)
          ensure
            @condition = backup_condition
          end
        else
          call_without_easy_extensions(env)
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActionDispatch::Reloader', 'EasyPatch::ActionDispatchReloaderPatch', :if => Proc.new { Rails.env.development? && Rails.version.start_with?('4') }
