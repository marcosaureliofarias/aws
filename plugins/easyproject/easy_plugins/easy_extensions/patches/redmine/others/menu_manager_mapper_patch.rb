module EasyPatch
  module MenuManagerMapperPatch

    def self.included(base)
      base.include(InstanceMethods)
    end

    module InstanceMethods

      def easy_delete(name)
        if (found = self.find(name))
          found.parent.remove!(found)
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::MenuManager::Mapper', 'EasyPatch::MenuManagerMapperPatch'
