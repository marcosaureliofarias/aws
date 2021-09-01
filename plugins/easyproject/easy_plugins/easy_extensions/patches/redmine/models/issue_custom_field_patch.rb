module EasyPatch
  module IssueCustomFieldPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        def easy_groupable?
          true
        end

      end
    end

    module InstanceMethods
    end

    module ClassMethods
    end
  end

end
EasyExtensions::PatchManager.register_model_patch 'IssueCustomField', 'EasyPatch::IssueCustomFieldPatch'
