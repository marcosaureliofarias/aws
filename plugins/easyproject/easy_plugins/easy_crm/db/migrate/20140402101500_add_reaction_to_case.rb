class AddReactionToCase < ActiveRecord::Migration[4.2]
  def self.up

    add_column :easy_crm_cases, :need_reaction, :boolean, {:default => false, :null => false}

  end

  def self.down
  end

end
