module EasyExtensions
  module ApiServicesForExchangeRates
    class RatesEasysoftwareCom

      def self.exchange_table(base = nil, date = nil, currencies_iso_codes = nil)
        date ||= Date.today
        base ||= 'EUR'
        limit = 30 # support for 30 different currencies

        q = []
        q << "date|=|#{date.to_s}"
        q << "from|=|#{base}"

        response = HTTParty.get('https://rates.easysoftware.com/rates.json', query: { w: q.join(','), limit: limit })

        h = {}

        if response.parsed_response
          h['base']  = base
          h['rates'] = []

          response.parsed_response.each do |r|
            h['rates'] << [r['to'], r['rate']]
          end if response.parsed_response
        end

        h
      end
    end

  end
end
