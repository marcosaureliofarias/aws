module EasyTwofa
  module CipheredJSON

    def self.load(data)
      JSON.load(Redmine::Ciphering.decrypt_text(data))
    end

    def self.dump(data)
      result = Redmine::Ciphering.encrypt_text(JSON.dump(data))

      # Base64 on ruby complies with RFC 2045
      # After every 60 characters a new line is added
      # However new line doesn't fulfill regexp in decrypt_text
      result.delete("\n")
    end

  end
end
