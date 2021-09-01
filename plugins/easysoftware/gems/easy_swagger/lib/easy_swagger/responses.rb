module EasySwagger
  module Responses
    module Basics
      def self.extended(base)
        base.extend(NotAuthorized)
        base.extend(NotFound)
        base.extend(NotAllowed)
      end
    end
    module NotAuthorized
      def self.extended(base)
        base.response 401 do
          key :description, 'not authorized'
        end
      end
    end
    module NotFound
      def self.extended(base)
        base.response 404 do
          key :description, 'not found'
        end
      end
    end
    module NotAllowed
      def self.extended(base)
        base.response 406 do
          key :description, 'not allowed'
        end
      end
    end
    module UnprocessableEntity
      def self.extended(base)
        base.response 422 do
          key :description, 'unprocessable entity'
          content "application/json" do
            schema "$ref": "ErrorModel"
          end
          content "application/xml" do
            schema "$ref": "ErrorModel"
          end
        end
      end
    end

  end

end