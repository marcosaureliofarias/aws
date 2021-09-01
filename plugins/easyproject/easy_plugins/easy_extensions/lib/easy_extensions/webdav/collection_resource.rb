module EasyExtensions
  module Webdav
    class CollectionResource < Resource

      def collection?
        true
      end

      def allowed_methods
        ['OPTIONS', 'PROPFIND'].freeze
      end

    end
  end
end
