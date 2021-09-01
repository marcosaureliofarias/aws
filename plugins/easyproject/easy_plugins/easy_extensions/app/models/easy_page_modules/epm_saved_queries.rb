class EpmSavedQueries < EasyPageModule

  def category_name
    @category_name ||= 'others'
  end

  def get_show_data(settings, user, page_context = {})
    private_queries, public_queries, role_queries, easy_user_type_queries = Hash.new { |hsh, key| hsh[key] = [] }, Hash.new { |hsh, key| hsh[key] = [] }, Hash.new { |hsh, key| hsh[key] = Hash.new }, Hash.new { |hsh, key| hsh[key] = [] }

    if settings['queries'].present?
      queries = EasyQuery.registered_subclasses.keys.select { |query_name| settings['queries'].include?(query_name.underscore) }.map(&:constantize)

      query_visibility = []
      query_visibility << EasyQuery::VISIBILITY_PRIVATE if settings['saved_personal_queries'].present?
      query_visibility << EasyQuery::VISIBILITY_PUBLIC if settings['saved_public_queries'].present?
      query_visibility << EasyQuery::VISIBILITY_ROLES if settings['saved_roles_queries'].present?
      query_visibility << EasyQuery::VISIBILITY_EASY_USER_TYPES if settings['saved_easy_user_types_queries'].present?

      queries.each do |query_class|
        name            = query_class.name
        user_roles      = user.roles.preload(:easy_queries)
        visible_queries = query_class.sidebar_queries(query_visibility, user, false, { ignore_admin: true }).to_a.group_by(&:visibility)

        private_queries[name] = Array(visible_queries[EasyQuery::VISIBILITY_PRIVATE])
        public_queries[name]  = Array(visible_queries[EasyQuery::VISIBILITY_PUBLIC])
        role_queries[name]    = user_roles.inject({}) do |memo, role|
          r          = Array(visible_queries[EasyQuery::VISIBILITY_ROLES]).select { |q| role.easy_query_ids.include?(q.id) }
          memo[role] = r if r.any?
          memo
        end

        easy_user_type_queries[name] = Array(visible_queries[EasyQuery::VISIBILITY_EASY_USER_TYPES])
      end
    end

    return { :private_queries => private_queries, :public_queries => public_queries,
             :role_queries    => role_queries, :easy_user_type_queries => easy_user_type_queries, :selected => queries || [] }
  end

  def get_edit_data(settings, user, page_context = {})
    return { queries: EasyQuery.registered_subclasses.keys.map(&:underscore) }
  end

end
