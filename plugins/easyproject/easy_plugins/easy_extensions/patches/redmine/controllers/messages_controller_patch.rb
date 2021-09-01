module EasyPatch
  module MessagesControllerPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        helper :queries
        include QueriesHelper

        alias_method_chain :quote, :easy_extensions

      end
    end

    module InstanceMethods

      def quote_with_easy_extensions
        @subject = @message.subject
        @subject = "RE: #{@subject}" unless @subject.starts_with?('RE:')

        text     = @message.content.to_s.strip.gsub(%r{<pre>(.*?)</pre>}m, '[...]')
        @content = "#{ll(Setting.default_language, :text_user_wrote, @message.author)}\n> "
        if Setting.text_formatting == 'HTML'
          @content << content_tag(:blockquote, text.html_safe) + "\n\n"
        else
          @content << text.gsub(/(\r?\n|\r\n?)/, "\n> ") + "\n\n"
        end
      rescue ActiveRecord::RecordNotFound
        render_404
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'MessagesController', 'EasyPatch::MessagesControllerPatch'
