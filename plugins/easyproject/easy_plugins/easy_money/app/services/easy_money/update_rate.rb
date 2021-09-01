module EasyMoney
  class UpdateRate
    def self.call(easy_money_rate, new_attributes = {})
      new(easy_money_rate).call(new_attributes)
    end

    def initialize(easy_money_rate)
      @easy_money_rate = easy_money_rate
    end

    def call(new_attributes)
      if new_attributes[:unit_rate].present?
        @easy_money_rate.update new_attributes
      else
        remove_rate
      end

      @easy_money_rate
    end

    def remove_rate
      @easy_money_rate.destroy

      @easy_money_rate = EasyMoneyRate.find_rate(@easy_money_rate.rate_type_id, @easy_money_rate.entity_type, @easy_money_rate.entity_id, nil) || EasyMoneyRate.new(entity: @easy_money_rate.entity, easy_currency_code: @easy_money_rate.project&.easy_currency_code || EasyCurrency.default_code)
    end
  end
end
