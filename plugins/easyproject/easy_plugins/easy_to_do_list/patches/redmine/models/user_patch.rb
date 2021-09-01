module EasyToDoListModule
  module UserPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        has_many :easy_to_do_lists

      end
    end

    module InstanceMethods

    end

    module ClassMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'User', 'EasyToDoListModule::UserPatch'
