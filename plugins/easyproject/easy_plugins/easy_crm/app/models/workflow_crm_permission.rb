class WorkflowCrmPermission < WorkflowRule

  AVAILABLE_FIELDS = %w(name description project_id assigned_to_id external_assigned_to_id contract_date email email_cc telephone price next_action is_canceled is_finished easy_contact_ids author_id currency).sort!
  REQUIRED_FIELDS = %w(project_id name author_id easy_crm_case_status_id)

  belongs_to :old_status, class_name: 'EasyCrmCaseStatus'
  belongs_to :new_status, class_name: 'EasyCrmCaseStatus'

  remove_validation :role, 'presence'
  remove_validation :tracker, 'presence'

  validates_inclusion_of :rule, :in => %w(readonly required)
  validate :validate_field_name

  def self.rules_by_status_id
    RequestStore.store["#{self.name}_rules_by_status_id".to_sym] ||=
    WorkflowCrmPermission.all.inject({}) do |h,w|
      h[w.old_status_id] ||= {}
      h[w.old_status_id][w.field_name] ||= []
      h[w.old_status_id][w.field_name] << w.rule
      h
    end
  end

  def self.replace_permissions(permissions)
    transaction do
      permissions.each do |status_id, rule_by_field|
        rule_by_field.each do |field, rule|
          where(:old_status_id => status_id, :field_name => field).destroy_all
          WorkflowCrmPermission.create(:old_status_id => status_id, :field_name => field, :rule => rule) if rule.present?
        end
      end
    end
  end

  private

  def validate_field_name
    if !EasyCrmCaseCustomField.exists?(name: field_name) && !field_name.to_s.match(/^\d+$/) && !WorkflowCrmPermission::AVAILABLE_FIELDS.include?(field_name)
      errors.add :field_name, :invalid
    end
  end
end
