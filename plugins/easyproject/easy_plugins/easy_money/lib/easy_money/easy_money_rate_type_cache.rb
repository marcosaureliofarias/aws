module EasyMoney
  class EasyMoneyRateTypeCache < Struct
    def translated_name
      I18n.t("easy_money_rate_type.#{name}").html_safe
    end

    def to_param
      id.to_s
    end
  end
end