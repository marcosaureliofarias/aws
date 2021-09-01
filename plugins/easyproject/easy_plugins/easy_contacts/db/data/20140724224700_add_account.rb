class AddAccount < ActiveRecord::Migration[4.2]

  def up
    EasyContactType.create(:type_name => 'Account', :internal_name => 'account')
  end

  def down
  end

end
