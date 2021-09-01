class ChangeCountrySelectFieldType < ActiveRecord::Migration[4.2]

  def up
    codes_table = {}
    ISO3166::Country.all.each{|x| codes_table[x.alpha3] = x.alpha2}
    CustomValue.joins("JOIN #{CustomField.table_name} ON #{CustomField.table_name}.id = #{CustomValue.table_name}.custom_field_id").where(custom_fields: {field_format: 'easy_contact_country_select'})
      .find_each(batch_size: 50) do |custom_value|
        custom_value.update_column(:value, codes_table[custom_value.value])
      end

    CustomField.unscoped.where(field_format: 'easy_contact_country_select').update_all(field_format: 'country_select')
  end

  def down
    codes_table = {}
    ISO3166::Country.all.each{|x| codes_table[x.alpha2] = x.alpha3}
    CustomValue.joins("JOIN #{CustomField.table_name} ON #{CustomField.table_name}.id = #{CustomValue.table_name}.custom_field_id").where(custom_fields: {field_format: 'country_select'})
      .find_each(batch_size: 50) do |custom_value|
        custom_value.update_column(:value, codes_table[custom_value.value])
      end

    CustomField.unscoped.where(field_format: 'country_select').update_all(field_format: 'easy_contact_country_select')
  end

end
