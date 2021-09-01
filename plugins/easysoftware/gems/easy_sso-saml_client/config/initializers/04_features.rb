# This file define all features
#
# Rys::Feature.for_plugin(EasySso::SamlClient::Engine) do
#   Rys::Feature.add('easy_sso.saml_client.project.show')
#   Rys::Feature.add('easy_sso.saml_client.issue.show')
#   Rys::Feature.add('easy_sso.saml_client.time_entries.show')
# end

Rys::Feature.for_plugin(EasySso::SamlClient::Engine) do
  Rys::Feature.add('easy_sso.saml_client')
end
