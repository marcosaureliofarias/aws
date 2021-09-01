class ChangeEasyButtonQueryClass < EasyExtensions::EasyDataMigration
  def up
    EasyQuery.where(:type => 'EasyActionButtonQuery').update_all(:type => 'EasyButtonQuery')
  end

  def down
  end
end