class AddCKeditorToolbarConfigToEasySetting < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'ckeditor_toolbar_config', :value => 'Basic')
  end

  def self.down
    EasySetting.where(:name => 'ckeditor_toolbar_config').destroy_all
  end
end
