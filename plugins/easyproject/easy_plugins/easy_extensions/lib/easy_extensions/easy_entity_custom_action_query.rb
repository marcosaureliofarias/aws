module EasyExtensions
  class EasyEntityCustomActionQuery
    attr_reader :easy_query

    def initialize(easy_query)
      @easy_query = easy_query

    end

    def filters_for_select(sort_by = 'name')
      @easy_query.filters_for_select(sort_by).reject { |a| a[0].match(/_cf_|\./) }
    end

    def method_missing(m, *args, &block)
      @easy_query.send(m, *args, &block)
    end

  end
end
