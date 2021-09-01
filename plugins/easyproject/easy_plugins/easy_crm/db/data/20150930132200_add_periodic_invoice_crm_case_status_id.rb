class AddPeriodicInvoiceCrmCaseStatusId < ActiveRecord::Migration[4.2]
  def up
    status = EasyCrmCaseStatus.where(:internal_name => 'opportunity').first || EasyCrmCaseStatus.first
    EasySetting.create(:name => 'easy_invoicing_template_crm_case_status_id', :value => status.id) if status.present?
  end

  def down
  end
end
