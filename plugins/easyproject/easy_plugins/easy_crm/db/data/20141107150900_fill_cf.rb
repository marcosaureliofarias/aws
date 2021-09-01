class FillCf < ActiveRecord::Migration[4.2]
  def self.up
    cf_ids = EasyCrmCaseCustomField.pluck(:id)

    EasyCrmCaseStatus.all.each do |s|
      s.custom_field_ids = cf_ids
    end
  end

  def self.down
  end

end
