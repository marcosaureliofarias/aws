module Concerns
module EasyAgileControllerMethods

  def self.included(base)
    base.class_eval do
      cattr_accessor :assignment_class_name
    end
  end

  def assignment_class
    assignment_class_name.constantize
  end

  def phase_scope
    if params[:phase] == 'project_backlog'
      EasyAgileBacklogRelation.where(project_id: @easy_sprint.project_id)
    else
      assignment_class.with_phase(params[:phase])
    end
  end

  def reorder
    return head :ok unless params[:issue_ids].present?
    @positions = Issue.where(id: params[:issue_ids]).joins(:priority).order('enumerations.position desc').pluck("#{Issue.table_name}.id").each_with_index.map{|id, index| { issue_id: id, position: index + 1 } }
    @relations = {}
    phase_scope.where(issue_id: params[:issue_ids]).map{|x| @relations[x.issue_id] = x }
    @positions.each do |position|
      @relations[position[:issue_id]].update_columns(position: position[:position]) if @relations[position[:issue_id]]
    end

    respond_to do |format|
      format.api { render template: 'easy_kanban/priority_positions' }
    end
  end

  def count_position(entity, options = {})
    if options[:phase] == 'project_backlog'
      klass = EasyAgileBacklogRelation
      current = entity.position if entity && !entity.new_record?
    else
      klass = assignment_class
      current = entity.position if entity && !entity.phase_column_value_changed?
    end
    position ||= (klass.where(issue_id: options[:prev_item_id]).limit(1).pluck(:position).first.to_i + 1 if options[:prev_item_id].present?)
    position ||= (klass.where(issue_id: options[:next_item_id]).limit(1).pluck(:position).first.to_i if options[:next_item_id].present?)
    position -= 1 if current && position && current <= position
    position || current
  end

  # Returns formatted array of values for swimlane, filtered by corresponding filter from query
  # ==== Params
  # +swimlane+:: swimlane name as String
  # +query+:: EasyQuery object
  # ==== Examples
  # [['name1', 'id1'], ['name2', 'id2'], ...]
  def get_values_for_swimlane(swimlane, query)
    return [] unless query
    filter = query.available_filters[swimlane]
    return [] unless filter

    if swimlane == 'project_id'
      results = query.all_projects_values
    elsif query.remote_filter?(filter)
      options = filter
      if filter.has_key?(:source_options)
        options = options.merge(filter.delete(:source_options))
      end
      options[:no_limit] = true
      operator = query.operator_for(swimlane)
      values = query.values_for(swimlane)

      if values && operator
        values = query.personalized_field_value_for_statement(swimlane, values)
        association_name = swimlane.gsub('_id', '')
        association_model_name = query.entity.reflect_on_association(association_name)&.klass.table_name

        filter_statement = query.sql_for_field(swimlane, operator, values, nil, "#{association_model_name}.id")
      else
        filter_statement = query.send("available_#{swimlane}_additional_statement") if query.respond_to?("available_#{swimlane}_additional_statement")
      end

      results = send("#{filter[:source]}_values", formatted: true, filter_statement: filter_statement, options: options)
    else
      results = filter[:values]
      results = results.call if results.is_a?(Proc)
      results = query.filtered_values_for(swimlane, results)
    end

    results || []
  end

end
end
