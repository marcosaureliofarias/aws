class SetEasySelectLimit < ActiveRecord::Migration[4.2]
  def self.up
    EasySetting.create(:name => 'easy_select_limit', :value => 25)
  end

  def self.down
    EasySetting.where(:name => 'easy_select_limit').destroy_all
  end
end