module EasyContacts
  module IssuesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        helper :easy_contacts
        include EasyContactsHelper

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch('IssuesController', 'EasyContacts::IssuesControllerPatch')
