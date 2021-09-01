module EasyCrm
  module EasyPageLayoutControllerPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        helper :easy_crm
        include EasyCrmHelper

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'EasyPageLayoutController', 'EasyCrm::EasyPageLayoutControllerPatch'
