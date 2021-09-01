class EpmTagCloud < EasyPageModule

  DEFAULT_LIMIT = 20

  def self.translatable_keys
    [
        %w[name]
    ]
  end

  def category_name
    @category_name ||= 'others'
  end

  def get_show_data(settings, user, page_context = {})
    limit = tags_limit(settings)

    query = begin
      settings['easy_query_type'].classify.constantize.new
    rescue
      nil
    end

    tags  = query.entity.tag_counts_on(:tags, :order => { :taggings_count => :desc }, :limit => limit) if query

    queries = taggable_queries
    return { :queries => queries, :query => query, :tags => tags }
  end

  def get_edit_data(settings, user, page_context = {})
    limit = tags_limit(settings)

    queries = taggable_queries
    return { :queries => queries, :limit => limit }
  end

  def tags_limit(settings)
    (settings['limit'].presence || DEFAULT_LIMIT).to_i
  end

  def taggable_queries
    EasyExtensions::EasyTag.registered_taggables.map do |entity_class, options|
      query = EasyExtensions::EasyTag::easy_query_class(entity_class.constantize, options)
      if query.nil?
        nil
      else
        query_name = query.name.underscore
        [l("easy_query.name.#{query_name}"), query_name]
      end
    end
  end

end
