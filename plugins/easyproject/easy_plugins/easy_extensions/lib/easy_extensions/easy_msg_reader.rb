require 'mapi/msg'

module EasyExtensions
  class EasyMsgReader
    def initialize(filename)
      @filename = filename
    end

    def to_eml
      begin
        Mapi::Msg.open(@filename).to_mime.to_s
      rescue StandardError
      end
    end
  end
end