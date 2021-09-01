module EasyPrintableTemplates
  module UserPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)

      base.class_eval do

        alias_method_chain :remove_references_before_destroy, :easy_printable_templates

      end
    end

    module InstanceMethods

      def remove_references_before_destroy_with_easy_printable_templates
        remove_references_before_destroy_without_easy_printable_templates
        substitute = User.anonymous
        EasyPrintableTemplate.where(author_id: self.id).update_all(author_id: substitute.id)
      end

    end

    module ClassMethods
    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'User', 'EasyPrintableTemplates::UserPatch'
