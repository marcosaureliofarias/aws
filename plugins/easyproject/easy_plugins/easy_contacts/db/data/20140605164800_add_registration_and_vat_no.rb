# encoding: utf-8

class AddRegistrationAndVatNo < ActiveRecord::Migration[4.2]

  EASY_CONTACT_CFS = {
    :registration_no => [ "Registration number", "IČ" ],
    :vat_no          => [ "VAT registration number", "DIČ" ]
  }

  def up
    contact_types = EasyContactType.where(internal_name: %w{ corporate personal })
    EasyContactCustomField.transaction do
      EASY_CONTACT_CFS.each do |internal_name, names|
        en_name, cz_name = names
        cf = EasyContactCustomField.create!(
          name: en_name,
          internal_name: internal_name,
          non_deletable: true,
          field_format: 'string',
          contact_types: contact_types
        )
        EasyTranslation.create(:entity => cf, :entity_column => :name, :lang => :cs, :value => cz_name)
      end
    end
  end

  def down
    EasyContactCustomField.reset_column_information
    EasyContactCustomField.where(internal_name: EASY_CONTACT_CFS.keys).destroy_all
  end

end
