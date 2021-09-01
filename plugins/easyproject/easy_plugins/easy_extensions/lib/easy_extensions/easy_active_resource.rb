module EasyExtensions
  class EasyActiveResource < ActiveResource::Base
    self.include_root_in_json = true

    class << self
      attr_reader :api_key

      def api_key=(key)
        @api_key                          = key
        self.headers['X-Redmine-API-Key'] = @api_key
      end
    end

  end
end
