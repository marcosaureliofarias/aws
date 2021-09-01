# This file define all features
#
# Rys::Feature.for_plugin(Swagger::Engine) do
#   Rys::Feature.add('easy_swagger.project.show')
#   Rys::Feature.add('easy_swagger.issue.show')
#   Rys::Feature.add('easy_swagger.time_entries.show')
# end

Rys::Feature.for_plugin(EasySwagger::Engine) do
  Rys::Feature.add('easy_swagger')
end
