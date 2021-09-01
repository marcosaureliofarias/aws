# VAT no custom field validation
# - new API needs to be implemented, validation is uncommented until that time

# module EasyContactPatch
#   module StringFormatPatch
#
#     def self.included(base)
#       base.include(InstanceMethods)
#
#       base.class_eval do
#         alias_method_chain :validate_custom_value, :easy_contacts
#
#       end
#     end
#
#     module InstanceMethods
#
#       def validate_custom_value_with_easy_contacts(custom_value)
#         errors = validate_custom_value_without_easy_contacts(custom_value)
#
#         if custom_value.custom_field.internal_name == 'vat_no' && custom_value.value.present?
#           vat_no_validation = EasyContacts::EuVatNoValidator.new(custom_value.value).validate
#           errors << ::I18n.t(:invalid, :scope => [:activerecord, :errors, :messages]) unless vat_no_validation[:valid]
#         end
#         errors
#       end
#
#     end
#
#   end
# end
# EasyExtensions::PatchManager.register_model_patch 'Redmine::FieldFormat::StringFormat', 'EasyContactPatch::StringFormatPatch'
