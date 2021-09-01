# This file define all features
#
# Rys::Feature.for_plugin(EasySso::SamlServer::Engine) do
#   Rys::Feature.add('easy_sso.saml_server.project.show')
#   Rys::Feature.add('easy_sso.saml_server.issue.show')
#   Rys::Feature.add('easy_sso.saml_server.time_entries.show')
# end

Rys::Feature.for_plugin(EasySso::SamlServer::Engine) do
  Rys::Feature.add('easy_sso.saml_server')
end
