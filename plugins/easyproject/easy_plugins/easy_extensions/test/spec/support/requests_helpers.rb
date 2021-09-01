module Requests
  module JsonHelpers
    def json
      @json ||= JSON.parse(response.body).symbolize_keys
    end
  end
end
RSpec.configure do |config|
  config.include Requests::JsonHelpers, type: :controller
end
