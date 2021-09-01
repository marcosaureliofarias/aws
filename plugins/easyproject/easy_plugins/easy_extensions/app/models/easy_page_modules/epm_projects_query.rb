class EpmProjectsQuery < EpmEasyQueryBase

  def category_name
    @category_name ||= 'projects'
  end

  def permissions
    @permissions ||= [:view_project]
  end

  def query_class
    EasyProjectQuery
  end

  protected

  def get_entities(query, settings)
    entities = super
    if query && query.display_as_tree? && settings['output'] != 'calendar'
      ancestors           = []
      ancestor_conditions = entities.collect { |project| "(#{Project.quoted_left_column_name} < #{project.lft} AND #{Project.quoted_right_column_name} > #{project.rgt})" }
      if ancestor_conditions.any?
        ancestor_conditions = "(#{ancestor_conditions.join(' OR ')})  AND (#{Project.table_name}.id NOT IN (#{entities.collect(&:id).join(',')}))"
        ancestors           = Project.where(ancestor_conditions).collect { |p| p.nofilter = ' nofilter'; p }
      end

      entities.concat(ancestors)
      entities = entities.uniq.sort_by(&:lft)
    end
    entities
  end

end
