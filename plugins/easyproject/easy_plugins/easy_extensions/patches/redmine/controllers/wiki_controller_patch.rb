module EasyPatch
  module WikiControllerPatch

    def self.included(base)

      base.include(InstanceMethods)
      base.class_eval do

        alias_method_chain :edit, :easy_extensions

        after_action :mark_as_read, only: [:show]

        def mark_as_read
          @wiki.mark_as_read if @wiki
          if @content && !@content.new_record?
            if @content.respond_to?(:wiki_content) && @content.wiki_content
              @content.wiki_content.mark_as_read
            else
              @content.mark_as_read
            end
          end
        end
      end
    end

    module InstanceMethods
      def edit_with_easy_extensions
        if edit_without_easy_extensions != false
          respond_to do |format|
            format.html
          end
        end
      end
    end

  end
end
EasyExtensions::PatchManager.register_controller_patch 'WikiController', 'EasyPatch::WikiControllerPatch'
