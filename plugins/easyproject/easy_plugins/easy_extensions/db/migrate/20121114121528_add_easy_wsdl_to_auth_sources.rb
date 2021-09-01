class AddEasyWsdlToAuthSources < ActiveRecord::Migration[4.2]
  def self.up
    add_column :auth_sources, :easy_wsdl, :string
  end

  def self.down
    remove_column :auth_sources, :easy_wsdl
  end
end