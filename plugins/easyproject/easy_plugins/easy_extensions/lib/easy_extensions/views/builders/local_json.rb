module EasyExtensions
  module Views
    module Builders
      class LocalJson < Redmine::Views::Builders::Structure

        def initialize
          super(nil, nil)
        end

        def __to_hash
          @struct.first
        end

        def __to_json
          __to_hash.to_json
        end

      end
    end
  end
end
