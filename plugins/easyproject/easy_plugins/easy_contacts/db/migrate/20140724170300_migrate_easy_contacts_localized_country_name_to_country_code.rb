class MigrateEasyContactsLocalizedCountryNameToCountryCode < ActiveRecord::Migration[4.2]

  def up
    CustomValue.joins(:custom_field)
      .where("#{CustomField.table_name}.field_format" => 'easy_contact_country_select')
      .find_each(batch_size: 50) do |custom_value|

      EasyExtensions::SUPPORTED_LANGS.each do |locale|
        countries = I18n.t :easy_contact_country_select, locale: locale
        if country_code = countries.key(custom_value.value)
          custom_value.value = country_code
          custom_value.save
          break
        end
      end
    end
  end

  def down
  end

end
