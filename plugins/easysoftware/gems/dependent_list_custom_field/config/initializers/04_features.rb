# This file define all features
#
# Rys::Feature.for_plugin(DependentListCustomField::Engine) do
#   Rys::Feature.add('dependent_list_custom_field.project.show')
#   Rys::Feature.add('dependent_list_custom_field.issue.show')
#   Rys::Feature.add('dependent_list_custom_field.time_entries.show')
# end

Rys::Feature.for_plugin(DependentListCustomField::Engine) do
  Rys::Feature.add('dependent_list_custom_field')
end
