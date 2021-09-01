module Sprockets
  class EasyUglifierCompressor < Sprockets::UglifierCompressor
    def initialize(options = {})
      @cache_key = "#{self.class.name}:#{Autoload::Uglifier::VERSION}:#{VERSION}:#{DigestUtils.digest(options)}".freeze
      options[:comments] = /no_asset_compression/
      @options = options
    end

    def call(input)
      if input[:data].include?('no_asset_compression')
        input[:data]
      else
        super(input)
      end
    end
  end
end