Rys::Patcher.add('Redmine::FieldFormat') do
  apply_if_plugins :easy_extensions

  included do
  end

  instance_methods(feature: 'easy_computed_field_from_query') do
  end

  class_methods do
    def all
      if Rys::Feature.active?('easy_computed_field_from_query')
        super
      else
        super.except('easy_computed_from_query')
      end
    end
  end
end
