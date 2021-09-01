module RedmineRe
  module BasePatch
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    module ClassMethods
      def acts_as_re_artifact
        include Artifact
      end
    end
  end
end

RedmineExtensions::PatchManager.register_rails_patch 'ActiveRecord::Base', 'RedmineRe::BasePatch'
