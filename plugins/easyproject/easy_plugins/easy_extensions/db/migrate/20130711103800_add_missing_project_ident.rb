class AddMissingProjectIdent < ActiveRecord::Migration[4.2]
  def self.up
    Project.where(:identifier => nil).each do |p|
      p.update_column :identifier, p.id.to_s
    end
  end

  def self.down
  end

end