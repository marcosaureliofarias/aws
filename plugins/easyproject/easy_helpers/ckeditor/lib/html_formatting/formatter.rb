module EasyPatch
  module HTMLFormatting
    class Formatter < String
      include ActionView::Helpers::TagHelper

      RULES = [:tidy_html_from_editor, :rinku_auto_link, :inline_custom_auto_link]

      def to_html(*rules, &block)
        ret = self.dup
        RULES.each do |rule_name|
          ret = (method(rule_name).call(ret) || ret)
        end
        ret
      end

      private

      AUTO_LINK_RE = %r{
	                      (                          # leading text
	                        <\w+.*?>|                # leading HTML tag, or
	                        [^=<>!:'"/]|             # leading punctuation, or
	                        \{\{\w+\(|               # inside a macro?
	                        ^                        # beginning of line
	                      )
	                      (
                          (?:smb://)|
                          (?:file://)
	                      )
	                      (
	                        (\S+?)                   # url
	                        (\/)?                    # slash
	                      )
	                      ((?:&gt;)?|[^\w\=\/;\(\)]*?)               # post
	                      (?=<|\s|&nbsp;|$)
	    }x unless const_defined?(:AUTO_LINK_RE)

      def rinku_auto_link(text)
        Redmine::CodesetUtil.replace_invalid_utf8(Rinku.auto_link(text)) if defined?(Rinku)
      end

      # Turns all urls into clickable links (code from Rails).
      def inline_custom_auto_link(text, regex_rules = AUTO_LINK_RE)
        return unless EasySetting.value(:ckeditor_autolink_file_protocols)
        text.gsub!(regex_rules) do
          all, leading, proto, url, post = $&, $1, $2, $3, $6

          if leading =~ /<a\s/i || leading =~ /![<>=]?/ || leading =~ /\{\{\w+\(/
             #don't replace URL's that are already linked
             #and URL's prefixed with ! !> !< != (textile images)
            all
          else
             #Idea below : an URL with unbalanced parethesis and
             #ending by ')' is put into external parenthesis
            if ( url[-1]==?) and ((url.count("(") - url.count(")")) < 0 ) )
              url=url[0..-2] # discard closing parenth from url
              post = ")"+post # add closing parenth to post
            end

            tag = content_tag('a', proto + url, :href => "#{proto}#{url}", :class => 'external', :target => '_blank')
            %(#{leading}#{tag}#{post})
          end
        end
      end

      # Tidy html. Fix html tags for correct show pages.
      def tidy_html_from_editor(text)
        # Skip formatting html
        save_with = Nokogiri::XML::Node::SaveOptions::DEFAULT_HTML -
                    Nokogiri::XML::Node::SaveOptions::FORMAT

        Nokogiri::HTML::DocumentFragment.parse(text).to_html(save_with: save_with)
      end

    end
  end
end
