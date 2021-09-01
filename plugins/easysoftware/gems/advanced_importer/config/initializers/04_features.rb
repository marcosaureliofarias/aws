# This file define all features
#
# Rys::Feature.for_plugin(AdvancedImporter::Engine) do
#   Rys::Feature.add('advanced_importer.project.show')
#   Rys::Feature.add('advanced_importer.issue.show')
#   Rys::Feature.add('advanced_importer.time_entries.show')
# end

Rys::Feature.for_plugin(AdvancedImporter::Engine) do
  Rys::Feature.add('advanced_importer')
end
