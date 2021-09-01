module EasyPatch
  module MailPatch
    module BodyPatch

      def self.included(base)
        base.include(InstanceMethods)

        base.class_eval do
          alias_method_chain :encoded, :easy_extensions
        end
      end

      module InstanceMethods
        def encoded_with_easy_extensions(transfer_encoding = nil)
          if !multipart? && transfer_encoding == ''
            return raw_source
          else
            encoded_without_easy_extensions(transfer_encoding)
          end
        end

      end
    end

    module UtilitiesPatch

      def self.included(base)
        base.include(InstanceMethods)

        base.class_eval do
          alias_method_chain :quote_token, :easy_extensions
        end
      end

      module InstanceMethods
        def quote_token_with_easy_extensions(str)
          if str.is_a?(String)
            original_encoding = str.encoding
            ascii_str         = str.dup.force_encoding('ASCII-8BIT')
            if token_safe?(ascii_str)
              str
            else
              dquote(ascii_str).force_encoding(original_encoding)
            end
          else
            quote_token_without_easy_extensions(str)
          end
        end

      end
    end

    module TransferEncodingPatch

      def self.included(base)
        base.extend(ClassMethods)

        base.class_eval do
          class << self
            alias_method_chain :negotiate, :easy_extensions
          end
        end
      end

      module ClassMethods
        def negotiate_with_easy_extensions(message_encoding, source_encoding, str, allowed_encodings = nil)
          message_encoding = ::Mail::Encodings.get_encoding(message_encoding) || ::Mail::Encodings.get_encoding('8bit')
          source_encoding  = ::Mail::Encodings.get_encoding(source_encoding)

          if message_encoding && source_encoding && message_encoding.can_transport?(source_encoding) && source_encoding.compatible_input?(str)
            source_encoding
          else
            renegotiate(message_encoding, source_encoding, str, allowed_encodings)
          end
        end
      end

    end

  end
end

if Mail::VERSION.version == '2.7.0'
  # https://github.com/mikel/mail/pull/1191
  EasyExtensions::PatchManager.register_redmine_plugin_patch 'Mail::Utilities', 'EasyPatch::MailPatch::UtilitiesPatch'

  # https://github.com/mikel/mail/pull/1128
  EasyExtensions::PatchManager.register_redmine_plugin_patch 'Mail::Body', 'EasyPatch::MailPatch::BodyPatch'

  # https://github.com/mikel/mail/pull/1176
  EasyExtensions::PatchManager.register_redmine_plugin_patch 'Mail::Encodings::TransferEncoding', 'EasyPatch::MailPatch::TransferEncodingPatch'
end