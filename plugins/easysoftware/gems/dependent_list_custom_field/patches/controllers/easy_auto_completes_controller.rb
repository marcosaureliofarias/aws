Rys::Patcher.add('EasyAutoCompletesController') do
  apply_if_plugins :easy_extensions

  included do

    def dependent_list_possible_values
      cf = CustomField.find(params[:custom_field_id])

      # find custom field settings
      dependency_settings = cf.dependency_settings
      if dependency_settings.blank?
        render json: []
        return
      end

      # find customized entity
      customized_type = params[:customized_type].safe_constantize
      if customized_type
        customized = customized_type.find(params[:customized_id])
      else
        return render_404
      end

      parent_cf = cf.dependent_parent_cf
      parent_cf_value = Array.wrap(customized.custom_field_value(parent_cf)).reject(&:blank?) # can be multiple

      if parent_cf_value.any?
        possible_values = cf.possible_values
        possible_parent_cf_values = parent_cf.possible_values
        keys = parent_cf_value.map { |value| possible_parent_cf_values.index(value) }
        values = []
        keys&.each do |key|
          next unless (setting = dependency_settings[key.to_s])

          setting.select { |_k, v| v == '1' }.keys.each { |key2| values << possible_values[key2.to_i] }
        end

        render json: values.compact.uniq.map { |value| { text: value, value: value } }
      else
        render json: []
        return
      end
    rescue ActiveRecord::RecordNotFound
      render_404
    end

  end
end
