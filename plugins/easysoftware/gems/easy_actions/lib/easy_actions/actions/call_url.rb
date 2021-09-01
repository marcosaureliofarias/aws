module EasyActions
  module Actions
    class CallUrl < ::EasyActions::Actions::Base

      attr_accessor :url, :query, :headers, :body, :method

      validates :url, :method, presence: true

      def fire(entity)
        opts           = {}
        opts[:query]   = query if query.is_a?(Hash)
        opts[:headers] = headers if headers.is_a?(Hash)
        opts[:body]    = body if body.is_a?(Hash)

        response = get_response(url, opts)
        response.parsed_response
      end

      private

      def get_response(url, opts = {})
        case method
        when 'post'
          HTTParty.post(url, opts)
        when 'patch'
          HTTParty.patch(url, opts)
        when 'put'
          HTTParty.put(url, opts)
        when 'delete'
          HTTParty.delete(url, opts)
        when 'move'
          HTTParty.move(url, opts)
        when 'copy'
          HTTParty.copy(url, opts)
        when 'head'
          HTTParty.head(url, opts)
        when 'options'
          HTTParty.options(url, opts)
        else
          HTTParty.get(url, opts)
        end
      end

    end
  end
end
