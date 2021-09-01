class SetDefaultCurrencyAndFormat < ActiveRecord::Migration[4.2]

  def up
    currency_field = 'currency'

    EasyMoneySettings.where(name: currency_field, value: nil).delete_all

    if EasyMoneySettings.find_settings_by_name(currency_field).blank?
      setting = EasyMoneySettings.new
      setting.name  = currency_field
      setting.value = '$'
      setting.save
    end
  end

  def down
  end

end
