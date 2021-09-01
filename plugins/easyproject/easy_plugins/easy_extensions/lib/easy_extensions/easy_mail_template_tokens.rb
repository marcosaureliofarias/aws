module EasyExtensions
  module EasyMailTemplateTokens
    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do

        easy_mail_template_token 'user_signature', proc { |entity| User.current.easy_mail_signature || '' }

      end

    end

    module ClassMethods

      def easy_mail_template_token(token_or_tokens, replaceable_method)
        token_or_tokens            = [token_or_tokens] unless token_or_tokens.is_a?(Array)
        @easy_mail_template_tokens ||= []
        @easy_mail_template_tokens << [token_or_tokens.to_a, replaceable_method]
      end

      def easy_mail_template_tokens
        @easy_mail_template_tokens || []
      end

    end

    def replace_tokens(text)
      return nil unless text.is_a?(String)

      self.class.easy_mail_template_tokens.each do |token_or_tokens, replaceable_method|
        regexp = token_or_tokens.collect { |t| "%\s?#{t}\s?%" }.join('|')
        text.gsub!(Regexp.new(regexp), replaceable_method.call(self).to_s)
      end

      text
    end
  end
end
