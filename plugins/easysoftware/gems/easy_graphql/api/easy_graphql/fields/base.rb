# frozen_string_literal: true

module EasyGraphql
  module Fields
    class Base < GraphQL::Schema::Field

      def authorized?(object, ruby_args, context)
        if object
          PermissionResolver.visible?(object, name.underscore)
        else
          # For example `all_issues` is also field
          true
        end
      end

    end
  end
end
