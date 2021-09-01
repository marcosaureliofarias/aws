# This file define all features
#
# Rys::Feature.for_plugin(EmailFieldAutocomplete::Engine) do
#   Rys::Feature.add('email_field_autocomplete.project.show')
#   Rys::Feature.add('email_field_autocomplete.issue.show')
#   Rys::Feature.add('email_field_autocomplete.time_entries.show')
# end

Rys::Feature.for_plugin(EmailFieldAutocomplete::Engine) do
  Rys::Feature.add('email_field_autocomplete', default_db_status: Rails.env.test?)
end
