class AddCrmStatuses < ActiveRecord::Migration[4.2]
  def self.up
    EasyCrmCaseStatus.create(:name => 'Lead', :internal_name => 'lead', :is_default => true)
    EasyCrmCaseStatus.create(:name => 'Opportunity', :internal_name => 'opportunity')
    EasyCrmCaseStatus.create(:name => 'Quotation', :internal_name => 'quotation')
    EasyCrmCaseStatus.create(:name => 'Client', :internal_name => 'client')
    EasyCrmCaseStatus.create(:name => 'Upsale', :internal_name => 'upsale')
    EasyCrmCaseStatus.create(:name => 'Partner', :internal_name => 'partner')
  end

  def self.down
  end

end
