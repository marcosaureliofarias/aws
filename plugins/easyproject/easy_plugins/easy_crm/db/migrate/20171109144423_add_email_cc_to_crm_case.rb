class AddEmailCcToCrmCase < ActiveRecord::Migration[4.2]
  def change
    add_column :easy_crm_cases, :email_cc, :string, {null: true, limit: 2048}
  end
end
