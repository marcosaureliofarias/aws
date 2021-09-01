# https://bugs.ruby-lang.org/issues/14416

module EasyPatch
  module POPMailPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do
        alias_method_chain :pop, :easy_extensions
      end
    end

    module InstanceMethods
      def pop_with_easy_extensions(dest = +'', &block)
        pop_without_easy_extensions(dest, &block)
      end
    end
  end
end
EasyExtensions::PatchManager.register_redmine_plugin_patch 'Net::POPMail', 'EasyPatch::POPMailPatch', if: proc { ["2.5.0", "2.5.1"].include?(RUBY_VERSION) }
