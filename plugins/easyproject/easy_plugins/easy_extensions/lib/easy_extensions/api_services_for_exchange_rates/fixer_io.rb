module EasyExtensions
  module ApiServicesForExchangeRates
    class FixerIo
      include HTTParty
      base_uri 'api.fixer.io'
      #default base = 'EUR', date = nil = latest

      def self.exchange_table(base = nil, date = nil, currencies_iso_codes = nil)

        options           = {} #base = nill -> base = EUR
        options[:symbols] = currencies_iso_codes.join(',') if currencies_iso_codes
        options[:base]    = base if base
        date_for_fetch    = date && date >= Date.new(1999, 1, 4) ? date : 'latest'
        response          = nil
        begin
          Timeout::timeout(5) { response = get("/#{date_for_fetch}", query: options, timeout: 5) }
        rescue Exception
          return false
        end
        if response && response.header.code != 200
          response.parsed_response
        else
          false
        end
      end
    end

  end
end
