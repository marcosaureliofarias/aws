class DefaultAccount < ActiveRecord::Migration[4.2]

  def up
    acc = EasyContactType.where(:internal_name => 'account').first
    if acc
      acc.is_default = true
      acc.save
    end
  end

  def down
  end

end
