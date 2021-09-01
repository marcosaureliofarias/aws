Rys::Patcher.add('CustomValue') do
  apply_if_plugins :easy_extensions

  included do
    before_save :ensure_dependent_list_custom_field_values, if: :should_ensure_dependent_list?
  end

  instance_methods do
    # if user update custom field value from inline editing
    # ensure dependent custom fields values after one of dependent cf updated
    def ensure_dependent_list_custom_field_values
      # collect dependent custom field values  [list, dependent_list]
      dependent_cf_values = customized.custom_field_values.select {|cfv| ['list', 'dependent_list'].include? cfv.custom_field.format.format_name }
      grouped_by_parent = dependent_cf_values.group_by {|dcfv| dcfv.custom_field.dependent_parent_cf_id }
      return true if grouped_by_parent.keys.compact.blank?

      # find dependent custom fields of current (chain of dependent cfs)
      dependent_custom_fields = find_dependent_custom_fields(self.custom_field, grouped_by_parent)
      return true if dependent_custom_fields.blank?

      grouped_by_cf = dependent_cf_values.group_by {|dcfv| dcfv.custom_field }
      invalid_dependent_cfs = {} #dependent cfs which should be cleared
      dependent_custom_fields.map do |dependent_custom_field, parent_custom_field|
        dependent_cf_value = grouped_by_cf[dependent_custom_field]&.first
        dependent_value = dependent_cf_value&.value
        next unless dependent_value.present?

        parent_cf_with_invalid_value = invalid_dependent_cfs[parent_custom_field.id]
        if parent_cf_with_invalid_value
          parent_value = nil
        else
          parent_value = grouped_by_cf[parent_custom_field]&.first&.value
        end

        unless parent_value.present? 
          invalid_dependent_cfs[dependent_custom_field.id] = dependent_custom_field
          next
        end

        index_of_parent_selected_value = parent_custom_field.possible_values.index(parent_value)
        dependencies = dependent_custom_field.dependency_settings[index_of_parent_selected_value.to_s] || {}
        available_values = dependencies.select {|k, v| v == '1' }.keys.map do |value_index|
          dependent_custom_field.possible_values[value_index.to_i]
        end

        unless available_values.include?(dependent_value)
          invalid_dependent_cfs[dependent_custom_field.id] = dependent_custom_field
        end
      end

      if invalid_dependent_cfs.any?
        CustomValue.where(customized_type: customized_type, customized_id: customized_id)
                  .where(custom_field_id: invalid_dependent_cfs.keys)
                  .update_all(value: nil)
      end
    end

    def find_dependent_custom_fields(parent_custom_field, grouped_by_parent, container = {})
      child_cfvalues = grouped_by_parent[parent_custom_field.id.to_s]
      return container if child_cfvalues.nil?
      child_cfvalues.each do |dcfv|
        container[dcfv.custom_field] = parent_custom_field
        find_dependent_custom_fields(dcfv.custom_field, grouped_by_parent, container)
      end
      container
    end

    private

      def should_ensure_dependent_list?
        Rys::Feature.active?('dependent_list_custom_field') &&
          ['list', 'dependent_list'].include?(custom_field.format.format_name) &&
          will_save_change_to_value? &&
          persisted?
      end
  end
end
