class RemoveEasyActionButtonQueries < EasyExtensions::EasyDataMigration
  def up
    EasyQuery.where(:type => 'EasyActionButtonQuery').delete_all unless defined?(EasyButtonQuery)
  end

  def down
  end
end