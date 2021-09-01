module EasyPatch
  module RepositoryPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        safe_attributes 'easy_repository_url',
                        :if => lambda { |repository, user| repository.new_record? }
        safe_attributes 'easy_username', 'easy_password', 'easy_database_url'

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Repository', 'EasyPatch::RepositoryPatch'
