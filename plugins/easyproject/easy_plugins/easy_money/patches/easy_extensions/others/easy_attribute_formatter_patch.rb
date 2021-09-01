module EasyMoney
  module EasyAttributeFormatterPatch

    def self.included(base)
      base.class_eval do
        def format_easy_money_price(*args)
          options = args.extract_options!
          price, project, easy_currency_code = args

          price = 0 unless price

          if options.fetch(:round, EasyMoneySettings.find_settings_by_name('round_on_list', project).to_boolean)
            options[:precision] = 0
          else
            options[:precision] = 2
          end

          options[:currency] ||= easy_currency_code ||
                                 project&.easy_currency_code ||
                                 EasyMoneySettings.find_settings_by_name('currency', project).to_s.presence ||
                                 EasyCurrency.default_code

          format_price(price, options[:currency], options)
        end
      end
    end
  end
end

EasyExtensions::PatchManager.register_concern_patch 'EasyExtensions::EasyAttributeFormatter', 'EasyMoney::EasyAttributeFormatterPatch'
