class CreateEasyQuerySettings < EasyExtensions::EasyDataMigration
  def self.up
    EasySetting.create! name: 'show_sum_row', value: false
    EasySetting.create! name: 'load_groups_opened', value: false
  end

  def self.down
    EasySetting.where(:name => ['show_sum_row', 'load_groups_opened']).destroy_all
  end
end
