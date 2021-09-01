module EasyPatch
  module BuildersPatch
    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do

        class << self

          alias_method_chain :for, :easy_extensions

        end

      end

    end

    module ClassMethods

      def for_with_easy_extensions(format, request, response, &block)
        format ||= request.format.symbol.to_s unless request.nil?

        for_without_easy_extensions(format, request, response, &block)
      end

    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Views::Builders', 'EasyPatch::BuildersPatch'
