module EasyQr

  class QRCode < RQRCode::QRCode

    attr_reader :original_string, :encoded_string

    def initialize(string, *args)
      super

      @original_string = string
      @encoded_string  = Base64.urlsafe_encode64(string)
    end

  end

  def self.generate_qr(text)
    qr_size = 3
    qr      = nil
    while qr == nil && qr_size < 30 # daily WTF :o)
      begin
        qr = EasyQr::QRCode.new(text, size: qr_size, level: :l)
      rescue RQRCodeCore::QRCodeRunTimeError
        qr_size += 1
      end
    end
    qr
  end

  def self.generate_image(text, options = {})
    qr = generate_qr(text)
    qr.as_png(border_modules: 1, size: (options[:size] || 256).to_i) if qr
  end

  def self.easy_printable_template
    EasyPrintableTemplate.find_by(internal_name: 'easy_qr')
  end

end
