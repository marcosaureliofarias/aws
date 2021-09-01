class AddCrmStatuses2 < ActiveRecord::Migration[4.2]
  def self.up
    s = EasyCrmCaseStatus.where(:internal_name => 'client').first
    if s
      s.name = 'Contract won'
      s.save
    end
  end

  def self.down
  end

end
