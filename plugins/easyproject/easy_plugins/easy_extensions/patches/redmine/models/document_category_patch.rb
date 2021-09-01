module EasyPatch
  module DocumentCategoryPatch

    def self.included(base)

      base.class_eval do

        acts_as_restricted
        acts_as_easy_translate

      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'DocumentCategory', 'EasyPatch::DocumentCategoryPatch'
