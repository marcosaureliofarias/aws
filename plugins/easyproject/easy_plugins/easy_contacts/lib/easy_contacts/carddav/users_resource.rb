module EasyContacts
  module Carddav
    ##
    # EasyQueryResource
    #
    # This resource is read-only
    #
    class UsersResource < AddressBookResource

      def initialize(path, controller, query=nil)
        super(path, controller)
        @query = query
      end

      def controlled_access?
        true
      end

      def readable?
        true
      end

      def writeable?
        false
      end

      def entities(options={})
        check_query

        q = query || EasyUserQuery.new
        q.entities(options)
      end

      def last_updated
        entities(limit: 1, order: "#{User.table_name}.updated_on DESC").first
      end

      def grouped_entities_by_uid(id)
        User.visible.where(id: id).group_by{|user| user.id.to_s}
      end

      def child(entity)
        UserResource.new(path + '/' + entity.id.to_s + '.vcf', controller, entity)
      end

      def displayname
        result = I18n.t(:label_user_plural)
        result << " (#{query.name})" if query
        result
      end

      def query_id
        @query_id ||= path.match(/users_q(\d+)/).try(:[], 1)
      end

      def query
        @query ||= (query_id && EasyUserQuery.where(id: query_id).first)
      end

      def check_query
        # Defined wrong id
        if query_id && query.nil?
          raise NotFound
        end
      end

    end
  end
end
