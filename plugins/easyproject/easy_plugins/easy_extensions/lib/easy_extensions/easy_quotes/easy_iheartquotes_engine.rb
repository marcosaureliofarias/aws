module EasyExtensions
  module EasyQuotes

    class EasyIheartquotesEngine < EasyQuotesEngine

      def initialize(*args)
        super(args)
        @url = URI.parse('http://www.iheartquotes.com/api/v1/random')
      end

      def get_quote
        @url.query = URI.encode_www_form({
                                             :format    => 'json',
                                             :max_lines => 4,
                                             :source    => self.iheartquotes_source_list
                                         })
        response   = EasyUtils::HttpUtils.get_request(@url)
        if response && response.is_a?(Net::HTTPSuccess)
          @quote = JSON.parse(response.body)
        end
        self
      rescue StandardError
        self
      end

      def author
        if text && text.match(/--(.*$)/)
          return $1
        end
      end

      def text
        @quote && @quote['quote']
      end

      def to_s
        text
      end

      def to_xml
        @quote.to_xml(:root => 'quote')
      end

      def iheartquotes_source_list
        'esr+humorix_misc+humorix_stories+macintosh+starwars'
      end

    end

  end
end
