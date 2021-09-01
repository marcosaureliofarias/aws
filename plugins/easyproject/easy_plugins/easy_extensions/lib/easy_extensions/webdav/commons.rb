module EasyExtensions
  module Webdav
    ##
    # EasyExtensions::Webdav::CData
    #
    # String which contains illegal characters
    # For examle HTML which cannot be passed to XML
    #
    class CData < String
    end
  end
end
