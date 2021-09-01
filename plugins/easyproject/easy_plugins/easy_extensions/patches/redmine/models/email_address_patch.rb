module EasyPatch
  module EmailAddressPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        belongs_to :user, :touch => true

      end
    end

    module InstanceMethods
    end

    module ClassMethods
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'EmailAddress', 'EasyPatch::EmailAddressPatch'
