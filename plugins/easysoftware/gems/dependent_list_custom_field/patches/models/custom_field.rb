Rys::Patcher.add('CustomField') do
  apply_if_plugins :easy_extensions

  included do
    scope :dependent_parents, -> (dependent_cf) { where(type: dependent_cf.type, field_format: ['list', 'dependent_list']).where.not(id: dependent_cf.id) }
    validate :validate_dependent_list_custom_field, if: -> { Rys::Feature.active?('dependent_list_custom_field') && format.format_name == 'dependent_list'}
  end

  instance_methods do

    def dependent_parent_cf_id
      settings['dependent_custom_field'].presence
    end

    def dependent_parent_cf
      @dependent_parent_cf ||= CustomField.find_by(id: dependent_parent_cf_id)
    end

    def dependency_settings
      settings['dependency_settings'].presence || {}
    end

    private

      def validate_dependent_list_custom_field
        if dependent_parent_cf.nil?
          errors.add :base, l(:error_dependent_list_custom_field_parent_is_blank)
        end
      end
  end
end
