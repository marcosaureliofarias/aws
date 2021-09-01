module EasyPatch
  module WelcomeControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        skip_before_action :check_if_login_required, :only => :robots

      end
    end

    module InstanceMethods
    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'WelcomeController', 'EasyPatch::WelcomeControllerPatch'
