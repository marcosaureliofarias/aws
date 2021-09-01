class AddCfToAccount < ActiveRecord::Migration[4.2]

  def up
    ct = EasyContactType.where(:internal_name => 'account').first

    EasyContactCustomField.joins(:contact_types).preload(:contact_types).where(["#{EasyContactType.table_name}.internal_name = ?", 'corporate']).each do |cf|
      cf.contact_types << ct if !cf.contact_types.include?(ct)
    end
  end

  def down
  end

end
