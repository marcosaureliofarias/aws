module EasyServiceManager
  class Service

    attr_reader :value, :valid_for

    def initialize
      @valid_for = 0
    end

    def value=(data)
      @value = data
    end

    def valid_for=(data)
      @valid_for = data.to_i
    end

    def execute
      raise NotImplementedError
    end

    def decrypt(string)
      if !EasyServiceManager.public_key || !File.exist?(EasyServiceManager.public_key)
        raise 'Public key is missing'
      end

      pubkey = OpenSSL::PKey::RSA.new(File.read(EasyServiceManager.public_key))
      string = Base64.urlsafe_decode64(string)
      pubkey.public_decrypt(string)
    end

    def encrypt(string)
      if !EasyServiceManager.private_key || !File.exist?(EasyServiceManager.private_key)
        raise 'Private key is missing'
      end

      pkey = OpenSSL::PKey::RSA.new(File.read(EasyServiceManager.private_key))
      string = pkey.private_encrypt(string)
      Base64.urlsafe_encode64(string, padding: false)
    end

    def token
      result = []

      # If logic will change
      result << 'v1'

      # Valid until
      result << (Time.now + @valid_for.minutes).utc.iso8601

      # The value
      result << JSON.dump(@value)

      encrypt(result.join('--'))
    end

    def token=(data)
      _, valid_until, value = decrypt(data).split('--', 3)

      if Time.iso8601(valid_until).utc < Time.now.utc
        raise 'Token expired'
      end

      @value = JSON.parse(value)
    end

  end
end
