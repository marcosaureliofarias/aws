class EasyContactCustomField < CustomField

  CONTACTS_TREE_CF_COUNT = 5

  has_and_belongs_to_many :contact_types, :class_name => 'EasyContactType', :join_table => "#{table_name_prefix}custom_fields_easy_contact_type#{table_name_suffix}", :foreign_key => 'custom_field_id', :association_foreign_key => 'easy_contact_type_id'
  after_save :invalidate_cache, :if => proc { |cf| cf.attribute_names.include?('disabled') && cf.saved_change_to_disabled? }

  safe_attributes 'contact_type_ids'

  def form_fields
    super + [:is_primary, :show_empty, :is_filter, :searchable, :clear_when_anonymize]
  end

  def type_name
    :label_easy_contact
  end

  def easy_groupable?
    true
  end

  def possible_country_codes
    self.possible_countries.stringify_keys.keys
  end

  def possible_countries
    l(:easy_contact_country_select, :default => {})
  end

  def possible_values
    if self.field_format == 'easy_contact_country_select'
      return @possible_values if @possible_values.present?
      c = self.possible_countries
      values = c.map { |code, name| [ name, code.to_s ] }
      values.sort! { |a,b| a.first <=> b.first }
      @possible_values = values
    else
      super
    end
  end

  def invalidate_cache
    Rails.cache.delete("easy_contact_cf/#{internal_name}_id")
  end

end
