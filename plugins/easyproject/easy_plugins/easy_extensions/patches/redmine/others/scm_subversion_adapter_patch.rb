require 'redmine/scm/adapters/subversion_adapter'

module EasyPatch
  module ScmSubversionAdapterPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :credentials_string, :easy_extensions
      end
    end

    module InstanceMethods
      def credentials_string_with_easy_extensions
        str = credentials_string_without_easy_extensions
        if EasySetting.value('dont_verify_server_cert')
          if self.class.client_version_above?([1, 9, 0])
            str << ' --trust-server-cert-failures="unknown-ca,cn-mismatch,expired,not-yet-valid,other"'
          else
            str << ' --trust-server-cert'
          end
        end
        str
      end
    end
  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Scm::Adapters::SubversionAdapter', 'EasyPatch::ScmSubversionAdapterPatch'
