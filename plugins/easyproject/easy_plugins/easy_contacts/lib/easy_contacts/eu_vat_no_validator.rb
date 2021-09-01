module EasyContacts
  class EuVatNoValidator

    VALIDATION_URL = "http://isvat.appspot.com/"

    def initialize(vat_no)
      @vat_no = vat_no.strip
    end

    def validate
      url = [ VALIDATION_URL, @vat_no[0..1], @vat_no[2..-1] ].join('/')
      res = open(url).read.to_boolean rescue false
      {
        valid: res
      }
    end

  end
end
