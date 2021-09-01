module EasyIntegrations
  class EntitiesFinder

    def initialize(easy_integration)
      @easy_integration = easy_integration
    end

    def entities
      @entities ||= if @easy_integration.use_query?
                      find_from_query || []
                    else
                      []
                    end
    end

    protected

    def create_query
      return nil if @easy_integration.query_settings.blank?
      query_klass = @easy_integration.query_settings['type']
      return nil if query_klass.blank?
      query = query_klass.safe_constantize&.new
      return nil unless query

      query.from_params(@easy_integration.query_settings)
      query
    end

    def find_from_query
      @easy_integration.execute_as_user.execute do
        create_query&.entities
      end
    end

  end
end
