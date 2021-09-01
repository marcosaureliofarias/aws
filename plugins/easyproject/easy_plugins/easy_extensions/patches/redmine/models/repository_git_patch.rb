module EasyPatch
  module RepositoryGitPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        def ensure_repository!
          if (path = scm.ensure!(easy_repository_url)).present?
            update_columns(url: path.to_s, root_url: path.to_s)
          end
        end


      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Repository::Git', 'EasyPatch::RepositoryGitPatch'
