class EasyCrmContactQuery < EasyContactQuery

  def query_after_initialize
    super
    self.easy_query_entity_controller = 'easy_crm_contacts'
    self.export_formats = ActiveSupport::OrderedHash.new
  end

  def entity_scope
    @entity_scope ||= EasyContact.visible.eager_load(:easy_crm_cases)
  end

  def columns
    super + [EasyQueryColumn.new(:easy_crm_cases, :inline => false)]
  end

  def self.chart_support?
    true
  end

  def available_filters
    return @easy_crm_contact_available_filters unless @easy_crm_contact_available_filters.blank?
    @easy_crm_contact_available_filters = super

    #add_custom_fields_filters(EasyCrmCaseCustomField)

    #add_associations_custom_fields_filters :easy_crm_cases

    @easy_crm_contact_available_filters
  end

  def sql_for_xproject_id_field(field, operator, value)
    sql_for_field(field, operator, value, EasyCrmCase.table_name, 'project_id')
  end

end
