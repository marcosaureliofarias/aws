module EasyPatch
  module Models
    def self.included(base)

      base.class_eval do
        acts_as_easy_translate
      end

    end
  end
end

# We cant't call acts_as_easy_translate directly in EasyQuery class, because we touch EasyQuery in after_init files,
# which is before our patches are applied and #acts_as_easy_translate method touches Project, which includes
# Redmine::NestedSet::ProjectNestedSet which we patch, but at this time the patch (NestedSetTraversingPatch) is not
# applied yet, and we did not figure out how to add Class methods via patch to already included module.
# Long story short: Project.each_with_easy_level is not defined
RedmineExtensions::PatchManager.register_model_patch 'EasyQuery', 'EasyPatch::Models'
