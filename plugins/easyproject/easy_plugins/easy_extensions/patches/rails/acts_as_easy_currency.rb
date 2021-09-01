module EasyPatch
  module ActsAsEasyCurrency

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def acts_as_easy_currency(price_method = :price, currency_method = :easy_currency_id, exchange_rate_date = :updated_at, _options = {})

        EasyEntityWithCurrency.add(self)

        unless method_defined?(:currency_options)
          cattr_accessor :currency_options
          send :include, EasyPatch::ActsAsEasyCurrency::EasyCurrencyMethods
        end

        self.currency_options ||= []
        self.currency_options << { price_method: price_method, currency_method: currency_method, exchange_rate_date: exchange_rate_date }

        define_method(price_method) do |currency = nil|
          base_currency            = nested_send(currency_method)
          currency                 ||= base_currency
          price_in_currency_method = price_method.to_s + '_' + currency.to_s
          if has_changes_to_save?
            if currency && base_currency && currency != base_currency
              date                                      = send(exchange_rate_date)
              @easy_exchange_rates                      ||= {}
              @easy_exchange_rates[date]                ||= {}
              @easy_exchange_rates[date][base_currency] ||=
                  (EasyCurrencyExchangeRate.rates_by_iso(base_currency, date).pluck(:to_code, :rate) << [base_currency, 1]).to_h
              (@easy_exchange_rates[date][base_currency][currency].presence || 1.0) * read_attribute(price_method).to_f
            else
              read_attribute(price_method)
            end
          elsif currency && activated_currency_columns.include?(price_in_currency_method) && (value = read_attribute(price_in_currency_method).presence)
            value
          else
            read_attribute(price_method)
          end
        end

        if method_defined?(:journalized_options) && table_exists?
          journalized_options[:non_journalized_columns] += self.column_names.select { |x| /#{price_method}_/.match?(x) }
        end

      end

    end

    module EasyCurrencyMethods

      def self.included(base)
        base.class_eval do
          before_save :recalculate_prices_in_currencies, if: :should_recalculate?

          def recalculate_prices_in_currencies
            new_values_hash = {}
            currency_options.each do |price_definition|
              if read_attribute(price_definition[:price_method]).nil?
                new_values_hash.merge!(attribute_names.select { |x| /^#{price_definition[:price_method]}_[A-Z]{3}/.match?(x) }.zip([nil]).to_h)
              else
                iso_code            = send(price_definition[:currency_method])
                easy_exchange_rates = EasyCurrencyExchangeRate.rates_by_iso(iso_code, send(price_definition[:exchange_rate_date])).pluck(:to_code, :rate)
                if easy_exchange_rates.any?
                  easy_exchange_rates << [iso_code, 1]
                  easy_exchange_rates.each do |exchange_rate|
                    new_values_hash[price_definition[:price_method].to_s + '_' + exchange_rate[0]] = read_attribute(price_definition[:price_method]) * exchange_rate[1]
                  end
                  new_values_hash[price_definition[:price_method].to_s + '_' + iso_code] = read_attribute(price_definition[:price_method])
                else
                  EasyCurrency.activated.pluck(:iso_code).each do |code|
                    new_values_hash[price_definition[:price_method].to_s + '_' + code] = read_attribute(price_definition[:price_method])
                  end
                end
              end
            end
            self.attributes = new_values_hash.slice(*self.class.column_names)
          end

          def read_attribute_for_validation(key)
            return read_attribute(key) if currency_options.map { |x| x[:price_method] }.include?(key)

            super
          end

          def default_currency
            @default_currency ||= send(currency_options.first[:currency_method])
          end

          def activated_currency_columns
            attribute_names.select { |x| /^(#{currency_options.map { |y| y[:price_method] }.join('|')})_[A-Z]{3}/.match?(x) }
          end

          def currency_columns
            @currency_columns ||= currency_options.map { |x| x[:price_method] }.product(EasyCurrency.pluck(:iso_code)).map { |x| x.join('_') }
          end

          private

          def should_recalculate?
            EasyEntityWithCurrency.initialized?
          end
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActiveRecord::Base', 'EasyPatch::ActsAsEasyCurrency'
