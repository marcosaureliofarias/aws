module EasyPatch
  module ProjectCustomFieldPatch

    def self.included(base)
      base.class_eval do

        def easy_groupable?
          true
        end

      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'ProjectCustomField', 'EasyPatch::ProjectCustomFieldPatch', after: 'CustomField'
