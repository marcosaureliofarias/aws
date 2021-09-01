class EasyCrmCaseCustomField < CustomField

  has_and_belongs_to_many :easy_crm_case_statuses, :class_name => 'EasyCrmCaseStatus', :join_table => "#{table_name_prefix}custom_fields_easy_crm_case_status#{table_name_suffix}", :foreign_key => 'custom_field_id'

  scope :non_computed_fields, lambda { where.not(:field_format => 'easy_computed_token') }

  safe_attributes 'easy_crm_case_status_ids'

  def type_name
    :label_easy_crm_cases
  end

  def form_fields
    [:is_required, :is_filter, :searchable]
  end

  def easy_groupable?
    true
  end

end
