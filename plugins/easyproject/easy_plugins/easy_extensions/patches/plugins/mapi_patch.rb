require 'mapi/msg'

module EasyPatch
  module MapiPropertySetPatch
    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :body_html, :easy_extensions
      end
    end

    module InstanceMethods
      def body_html_with_easy_extensions
        body_html_without_easy_extensions
        @body_html = Redmine::CodesetUtil.replace_invalid_utf8(@body_html)
      end
    end
  end

  module MapiMessagePatch
    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :body_to_mime, :easy_extensions
      end
    end

    module InstanceMethods
      def body_to_mime_with_easy_extensions
        if props.body_rtf or props.body_html
          mime = Mapi::Mime.new "Content-Type: multipart/alternative\r\n\r\n"
          mime.parts << Mapi::Mime.new("Content-Type: text/plain; charset=utf-8\r\n\r\n#{props.body}") if props.body
          mime.parts << Mapi::Mime.new("Content-Type: text/html; charset=utf-8\r\n\r\n#{props.body_html}") if props.body_html
          mime
        else
          Mapi::Log.debug "taking that other path"
          Mapi::Mime.new "Content-Type: text/plain\r\n\r\n#{props.body}"
        end
      end
    end
  end

  module MapiRTFPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        class << self
          alias_method_chain :rtf2html, :easy_extensions
        end
      end
    end

    module ClassMethods
      def rtf2html_with_easy_extensions(rtf)
        scan = StringScanner.new rtf
        return unless rtf["\\fromhtml"]
        if scan.scan_until(/\\ansicpg/)
          code_page = "windows-#{scan.scan(/\d+/)}"
        else
          code_page = 'us-ascii'
        end
        result = rtf2html_without_easy_extensions(rtf)
        result ? result.encode('utf-8', code_page) : nil
      end
    end
  end
end
EasyExtensions::PatchManager.register_redmine_plugin_patch 'Mapi::PropertySet', 'EasyPatch::MapiPropertySetPatch'
EasyExtensions::PatchManager.register_redmine_plugin_patch 'Mapi::Message', 'EasyPatch::MapiMessagePatch'
EasyExtensions::PatchManager.register_redmine_plugin_patch 'Mapi::RTF', 'EasyPatch::MapiRTFPatch'

