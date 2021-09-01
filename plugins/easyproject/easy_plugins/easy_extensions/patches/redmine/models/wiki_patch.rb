module EasyPatch
  module WikiPatch

    def self.included(base)
      base.include(InstanceMethods)
      base.class_eval do

        acts_as_user_readable

      end
    end

    module InstanceMethods

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Wiki', 'EasyPatch::WikiPatch'
