class AddLockToCase < ActiveRecord::Migration[4.2]
  def self.up

    add_column :easy_crm_cases, :lock_version, :integer, {:default => 0, :null => false}

  end

  def self.down
  end

end
