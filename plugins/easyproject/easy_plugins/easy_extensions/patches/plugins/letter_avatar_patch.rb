module EasyPatch
  module LetterAvatarPatch

    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        class << self
          alias_method_chain :cached_path, :easy_extensions
        end
      end
    end

    module ClassMethods

      def cached_path_with_easy_extensions(identity, size)
        digest = Digest::SHA1.hexdigest("#{identity.letter}/#{identity.color.join('_')}")
        dir    = "#{cache_path}/#{digest}"
        FileUtils.mkdir_p(dir)

        "#{dir}/#{size}.png"
      end

    end

  end
end

EasyExtensions::PatchManager.register_redmine_plugin_patch 'LetterAvatar::Avatar', 'EasyPatch::LetterAvatarPatch'
