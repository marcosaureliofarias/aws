module EasyContacts
  module EasyPatch
    module UserFormatPatch

      def self.included(base)
        base.include(InstanceMethods)

        base.class_eval do

          alias_method_chain :possible_values_records, :easy_contacts

        end
      end


      module InstanceMethods

        def possible_values_records_with_easy_contacts(custom_field, object=nil)
          if object && object.is_a?(EasyContact)
            User.active.easy_type_internal.visible.sorted
          else
            possible_values_records_without_easy_contacts(custom_field, object)
          end
        end

      end
    end
  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::FieldFormat::UserFormat', 'EasyContacts::EasyPatch::UserFormatPatch'
