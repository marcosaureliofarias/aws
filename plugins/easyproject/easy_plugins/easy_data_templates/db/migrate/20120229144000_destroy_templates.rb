class DestroyTemplates < ActiveRecord::Migration[4.2]
  def self.up
    EasyDataTemplate.destroy_all
  end

  def self.down
  end
end
