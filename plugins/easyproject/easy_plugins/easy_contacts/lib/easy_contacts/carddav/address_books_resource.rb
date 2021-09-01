module EasyContacts
  module Carddav
    ##
    # AddressBooksResource
    #
    # All address books
    #
    class AddressBooksResource < Resource

      def collection?
        true
      end

      def property_names
        ['resourcetype'].freeze
      end

      def allowed_methods
        ['OPTIONS', 'PROPFIND'].freeze
      end

      def children
        result = []
        result << UsersResource.new('/users', controller)
        result << EasyContactsResource.new('/easy_contact', controller)

        EasyUserQuery.visible.each do |query|
          result << UsersResource.new("/users_q#{query.id}", controller, query)
        end

        result
      end

    end
  end
end
