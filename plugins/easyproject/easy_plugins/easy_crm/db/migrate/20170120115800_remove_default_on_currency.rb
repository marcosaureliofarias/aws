class RemoveDefaultOnCurrency < ActiveRecord::Migration[4.2]
  def up
    change_column_default(:easy_crm_cases, :currency, nil)
  end

  def down
    change_column_default(:easy_crm_cases, :currency, 'EUR')
  end
end
