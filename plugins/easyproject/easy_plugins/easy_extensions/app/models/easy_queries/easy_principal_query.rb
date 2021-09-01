class EasyPrincipalQuery < EasyQuery 

  def searchable_columns
    ["#{Principal.table_name}.login", "#{Principal.table_name}.lastname", "#{Principal.table_name}.firstname", "(SELECT address FROM #{EmailAddress.table_name} WHERE user_id=#{Principal.table_name}.id AND is_default = #{self.class.connection.quoted_true} LIMIT 1)"]
  end

  def entity
    Principal
  end

  def entity_scope
    @entity_scope ||= Principal.active.visible.distinct
  end

  def self.get_assignable_principals(projects, term = '', options = {})
    query = new
    free_search_tokens = term.is_a?(String) ? term.split(' ') : []
    sql = query.assignable_principals_scope(projects, options)
    query.add_additional_scope(sql)
    query.add_additional_scope(Principal.group(User.arel_table[:id])
                                        .having(Member.arel_table[:project_id].count(true).eq(projects.count))
                              ) if projects.many?

    options = { joins: [members: :roles] }

    query.search_freetext(free_search_tokens, options)
  end

  def assignable_principals_scope(projects = [], options = {})
    types = options[:types]
    if types.nil?
      types = ['User']
      types << 'Group' if Setting.issue_group_assignment?
    end
    project_ids = projects.map(&:id)

    principals = Principal.arel_table
    members = Member.arel_table
    roles = Role.arel_table

    principals[:type].in(types).and(principals[:easy_system_flag].eq(false))
                               .and(members[:project_id].in(project_ids))
                               .and(roles[:assignable].eq(true)).to_sql
  end

  def search_freetext(tokens, options = {})
    options[:all_words] = true unless options.key?(:all_words)
    tokens              = [] << tokens unless tokens.is_a?(Array)

    token_clauses = statement_for_searching
    sql           = (['(' + token_clauses.join(' OR ') + ')'] * tokens.size).join(options[:all_words] ? ' AND ' : ' OR ')

    scope = create_entity_scope(options.merge(skip_group_order: true))
    if tokens.present? && token_clauses.present?
      scope = scope.where(search_freetext_where_conditions(sql, tokens, token_clauses))
    end
    scope.limit(options[:limit])
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

end
