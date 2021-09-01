class RecalculateEasyCurrencyForEasyMoneyEntities < EasyExtensions::EasyDataMigration
  def up
    if EasyCurrency.active_currencies_codes.any?
      EasyCurrency.reinitialize_tables

      if EasyCurrencyExchangeRate.where.not(valid_on: nil).any?
        EasyEntityWithCurrency.entities.each do |model|
          if model.name.start_with? 'EasyMoney'
            say_with_time "Recalculating #{model.name} price columns" do
              model.recalculate_prices_in_currencies
            end
          end
        end
      else
        say "No configured currency exchange rates"
      end

    end
  end

  def down
  end
end
