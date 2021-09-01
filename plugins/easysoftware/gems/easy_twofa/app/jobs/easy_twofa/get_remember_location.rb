# frozen_string_literal: true

require 'geocoder'

module EasyTwofa
  class GetRememberLocation < EasyActiveJob

    def perform(remember)
      result = Geocoder.search(remember.ip)
      ipinfo = result.first

      if ipinfo
        remember.address = ipinfo.address
        remember.save
      end

    rescue Geocoder::NetworkError
      raise ::EasyActiveJob::RetryException
    end

  end
end
