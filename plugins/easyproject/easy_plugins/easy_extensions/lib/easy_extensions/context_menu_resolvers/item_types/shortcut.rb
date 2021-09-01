module ContextMenuResolvers
  module ItemTypes
    class Shortcut < Base

      def type
        'shortcut'
      end

      def http_method
        'POST'
      end

    end
  end
end
