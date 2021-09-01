class CreateEasySettingHideLoginQuotes < ActiveRecord::Migration[4.2]
  def up
    EasySetting.create(:name => 'hide_login_quotes', :value => false)
  end

  def down
    EasySetting.where(:name => 'hide_login_quotes').delete_all
  end
end
