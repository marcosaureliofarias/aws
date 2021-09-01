class AddFiscal < ActiveRecord::Migration[4.2]
  def up
    EasySetting.create(:name => 'fiscal_day', :value => '01')
    EasySetting.create(:name => 'fiscal_month', :value => '01')
  end
end
