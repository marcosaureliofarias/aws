# FactoryBot.define do
#
#   factory :test do
#     sequence(:name) { |n| "Test ##{n}" }
#   end
#
# end
FactoryBot.define do

  factory :easy_entity_import do
    sequence(:name) { |n| "Import ##{n}" }
    entity_type { "Issue" }
    type { "EasyEntityCsvImport" }

    factory :easy_entity_csv_import, parent: :easy_entity_import, class: EasyEntityCsvImport do

    type { "EasyEntityCsvImport" }
    end

    factory :easy_entity_xml_import, parent: :easy_entity_import, class: EasyEntityXmlImport do

    type { "EasyEntityXmlImport" }
    end
  end

  factory :easy_entity_import_attributes_assignment, aliases: [:import_assignment] do
    easy_entity_import
    source_attribute { 0 }
    entity_attribute { "easy_external_id" }
  end

end
