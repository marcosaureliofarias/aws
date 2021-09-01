module Easy
  module Errors
    class Expected < StandardError

      def initialize(original_exception = nil, msg = nil)
        original_exception, msg = nil, original_exception if original_exception.is_a?(String)

        a = []
        a << "#{original_exception.class.name}: #{original_exception.message}" if original_exception
        a << "#{self.class.name}: #{msg}" if msg

        super(a.join(', '))
      end

    end
  end
end
