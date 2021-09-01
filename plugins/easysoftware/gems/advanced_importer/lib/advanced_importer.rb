require 'rys'

require 'advanced_importer/version'
require 'advanced_importer/engine'

module AdvancedImporter

  # Configuration of AdvancedImporter
  #
  # @example Direct configuration
  #   AdvancedImporter.config.my_key = 1
  #
  # @example Configuration via block
  #   AdvancedImporter.configure do |c|
  #     c.my_key = 1
  #   end
  #
  # @example Getting a configuration
  #   AdvancedImporter.config.my_key
  #

  # configure do |c|
  #   c.my_key = 'This is my private config for AdvancedImporter'
  #
  #   # System rys (not visible to the users)
  #   # c.systemic = true
  # end
  configure do |c|
    c.available_import_entities = %w[
      EasyEntityCsvImport
      EasyEntityXmlImport
      EasyEntityImports::EasyAsanaCsvImport
      EasyEntityImports::EasyIssueCsvImport
      EasyEntityImports::EasyIssueXmlImportMolMsProject
      EasyEntityImports::EasyJiraXmlImporter
      EasyEntityImports::EasyJournalCsvImport
      EasyEntityImports::EasyTimeEntryCsvImport
      EasyEntityImports::EasyUserCsvImport
    ]
  end

end