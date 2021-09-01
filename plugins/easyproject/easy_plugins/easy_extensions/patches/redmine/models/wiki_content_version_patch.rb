module EasyPatch
  module WikiContentVersionPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
      base.class_eval do

        acts_as_user_readable

      end
    end

    module InstanceMethods

    end

    module ClassMethods

      def easy_activity_custom_project_scope(scope, options, event_type)
        scope = scope.joins("LEFT JOIN #{WikiPage.table_name} ewikipage ON ewikipage.id = #{self.table_name}.page_id LEFT JOIN #{Wiki.table_name} ewiki ON ewiki.id = ewikipage.wiki_id")
        scope.where('ewiki.project_id in (?)', options[:project_ids])
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'WikiContent::Version', 'EasyPatch::WikiContentVersionPatch'
