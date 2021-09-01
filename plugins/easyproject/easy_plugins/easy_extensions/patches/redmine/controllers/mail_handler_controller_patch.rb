module EasyPatch
  module MailHandlerControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :index, :easy_extensions

      end

    end

    module InstanceMethods

      def index_with_easy_extensions
        options = params.dup
        email   = options.delete(:email)
        if EasyMailHandler.receive(email, options)
          head :created
        else
          head :unprocessable_entity
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'MailHandlerController', 'EasyPatch::MailHandlerControllerPatch'
