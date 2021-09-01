class CreateEasyRakeTaskSettings < EasyExtensions::EasyDataMigration
  def self.up
    EasySetting.create!(:name => 'easy_rake_task_period', :value => 300)
  end

  def self.down
    EasySetting.where(:name => 'easy_rake_task_period').destroy_all
  end
end
