class EasyRakeTaskComputedFromQuery < EasyRakeTask

  def self.recalculate_entity(entity)
    if entity.respond_to?(:available_custom_fields_scope)
      cfs = entity.available_custom_fields_scope.where(field_format: 'easy_computed_from_query')
    else
      cfs = entity.available_custom_fields.select { |cf| cf.field_format == 'easy_computed_from_query' }
    end

    User.current.as_admin do
      recalculate_cfs(cfs, entity.id)
    end

    true
  end

  def self.recalculate_cfs(cfs, entity_id = nil)
    queries = {}
    grouped_cfs = cfs.group_by { |cf| cf.class.customized_class }
    available_currencies = EasyCurrency.activated.pluck(:iso_code)

    grouped_cfs.each do |entity_class, custom_fields|
      custom_field_ids = []

      custom_fields.each do |cf|
        custom_field_ids << cf.id

        if !queries.has_key?(cf.easy_query_name)
          queries[cf.easy_query_name] = cf.create_clear_easy_query
        end
      end

      entity_scope = entity_class.preload(:custom_values);

      if entity_id
        entity_scope = entity_scope.where(id: entity_id);
      else
        if Date.today.wday != 6
          if entity_class.column_names.include?('updated_on')
            entity_scope = entity_scope.where("#{entity_class.table_name}.updated_on >= ?", Time.now.beginning_of_day - 2.day)
          elsif entity_class.column_names.include?('updated_at')
            entity_scope = entity_scope.where("#{entity_class.table_name}.updated_at >= ?", Time.now.beginning_of_day - 2.day)
          end
        end
      end

      entity_count = entity_scope.count
      started, log_time = Time.now, Time.now

      log_info "EasyRakeTaskComputedFromQuery: total #{entity_count} in #{entity_class.name.pluralize}."

      idx = 1

      entity_scope.find_each(batch_size: 1) do |entity|
        values = {}

        custom_fields.each do |cf|
          query = queries[cf.easy_query_name].dup
          cf.apply_easy_query_filters(query)

          currency = available_currencies.include?(cf.easy_query_column_currency_code) ? cf.easy_query_column_currency_code : nil
          values[cf.id.to_s] = cf.format.compute_value_from_query(cf, entity, query, currency)
        end

        entity.safe_attributes = {'custom_field_values' => values}

        all_cv_to_save = entity.build_custom_values_for_save

        entity.custom_values = all_cv_to_save

        CustomValue.transaction do
          all_cv_to_save.each do |cv|
            cv.save(validate: false) if custom_field_ids.include?(cv.custom_field_id)
          end
        end

        if (idx % 100) == 0
          log_info "EasyRakeTaskComputedFromQuery: progress #{idx} from #{entity_count} (#{(idx / entity_count.to_f * 100).to_i}%) in #{entity_class.name.pluralize} (running #{(Time.now - log_time).to_i}s)."
          log_time = Time.now
        end

        idx += 1
      end

      log_info "EasyRakeTaskComputedFromQuery: progress done in #{entity_class.name.pluralize} (running #{(Time.now - started).to_i}s)."
    end
  end

  def in_disabled_plugin?
    super || !available?
  end

  def active?
    super && available?
  end

  def visible?
    super && available?
  end

  def execute
    return false unless Rys::Feature.active?('easy_computed_field_from_query')
    cfs = CustomField.where(field_format: 'easy_computed_from_query').sorted.to_a

    User.current.as_admin do
      self.class.recalculate_cfs(cfs)
    end

    true
  end

  private

  def available?
    Redmine::Plugin.installed?(:easy_contacts) && Redmine::Plugin.installed?(:easy_crm) && Rys::Feature.active?('easy_computed_field_from_query')
  end

end
