# encoding: utf-8
module EasyExtensions
  module EasyQuotes
    class EasyCustomQuotesEngine < EasyQuotesEngine

      def available_quotes
        [
            { :text => "Ultimately spiritual awareness unfolds when you're flexible, when you're spontaneous, when you're detached, when you're easy on yourself and easy on others.", :author => "Deepak Chopra" },
            { :text => "Even if you are on the right track, you will get run over if you just sit there.", :author => "Will Rogers" },
            { :text => "No matter how good the team or how efficient the methodology, if we’re not solving the right problem, the project fails.", :author => "Woody Williams" },
            { :text => "Planning without action is futile, action without planning is fatal.", :author => "Cornelius Fitchner" },
            { :text => "We will either find a way, or make one.", :author => "Hannibal" },
            { :text => "When the territory and the map disagree, believe the territory.", :author => "Swiss Army Manual" },
            { :text => "Before anything can be repeatable or reusable, it must be usable", :author => "Woody Williams" },
            { :text => "A project is complete when it starts working for you, rather than you working for it.", :author => "Scott Allen" },
            { :text => "Get the right people. Then no matter what all else you might do wrong after that, the people will save you. That’s what management is all about.", :author => "Tom DeMarco" }
        ]
      end

      def get_quote
        @quote = available_quotes.sample
        self
      end

      def author
        @quote[:author]
      end

      def text
        @quote[:text]
      end

      def to_s
        is_loaded? && "<div>#{@quote[:text]}</div>\n<span>#{@quote[:author]}</span>".html_safe
      end


    end
  end
end
