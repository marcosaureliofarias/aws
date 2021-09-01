Rys::Patcher.add('Tracker') do

  apply_if_plugins :easy_extensions

  included do
    origin_core_fields = Tracker::CORE_FIELDS
    remove_const('CORE_FIELDS')
    const_set('CORE_FIELDS', (origin_core_fields + ['easy_duration']).freeze)
    remove_const('CORE_FIELDS_ALL')
    const_set('CORE_FIELDS_ALL', (Tracker::CORE_FIELDS_UNDISABLABLE + Tracker::CORE_FIELDS).freeze)
  end

  instance_methods(feature: 'easy_duration') do
    def disabled_core_fields
      fields = super
      if new_record?
        fields |= ['easy_duration']
      end
      fields
    end
  end
end
