require 'openssl'

module EasySso
  class SelfSignedCertificate

    DEFAULT_OPTIONS = {
        country:        "CZ",
        state:          nil,
        org:            "Easy Software",
        org_unit:       "Test",
        common_name:    "test.example.com",
        email:          "info@easysoftware.com",
        expire_in_days: 3653
    }

    def initialize(certificate, private_key)
      @certificate = certificate
      @private_key = private_key
    end

    def self.generate(opts = {})
      options = DEFAULT_OPTIONS.merge(opts)

      key = OpenSSL::PKey::RSA.new(2048)

      subject = ""
      subject << "/C=#{options[:country]}" if options[:country]
      subject << "/ST=#{options[:state]}" if options[:state]
      subject << "/O=#{options[:org]}" if options[:org]
      subject << "/OU=#{options[:org_unit]}" if options[:org_unit]
      subject << "/CN=#{options[:common_name]}" if options[:common_name]
      subject << "/emailAddress=#{options[:email]}" if options[:email]

      cert            = OpenSSL::X509::Certificate.new
      cert.subject    = cert.issuer = OpenSSL::X509::Name.parse(subject)
      cert.not_before = Time.now
      cert.not_after  = Time.now + options[:expire_in_days] * 24 * 60 * 60
      cert.public_key = key.public_key
      cert.serial     = options[:serial] || self.generate_serial
      cert.version    = 2

      ef                     = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate  = cert
      cert.add_extension ef.create_extension("basicConstraints", "CA:TRUE", true)
      cert.add_extension ef.create_extension("subjectKeyIdentifier", "hash")
      cert.add_extension ef.create_extension("authorityKeyIdentifier", "keyid:always,issuer:always")

      cert.sign key, OpenSSL::Digest::SHA256.new

      new(cert, key)
    end

    def self.generate_serial
      (Time.now.to_f * 10 ** 12).to_i + Random.rand(10000)
    end

    def self.parse_cert(string)
      OpenSSL::X509::Certificate.new(string)
    end

    def self.parse_key(string, pass = nil)
      OpenSSL::PKey.read(string, pass)
    end

    def self.extract_subject(cert)
      Hash[cert.subject.to_a.map { |i| [i[0].to_sym, i[1]] }]
    end

    def certificate
      @certificate.to_pem
    end

    def private_key
      @private_key.to_s
    end

  end
end
