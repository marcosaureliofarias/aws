module EasyMoney
  module EasyPrintableTemplatesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        helper :easy_money
        include EasyMoneyHelper

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'EasyPrintableTemplatesController', 'EasyMoney::EasyPrintableTemplatesControllerPatch', :if => Proc.new{Redmine::Plugin.installed?(:easy_printable_templates)}
