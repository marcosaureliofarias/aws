class AddProbability < ActiveRecord::Migration[4.2]
  def self.up

    drop_table(:easy_lead_scores) if table_exists?(:easy_lead_scores)
    remove_column(:easy_crm_cases, :easy_lead_score) if column_exists?(:easy_crm_cases, :easy_lead_score)

    create_table :easy_crm_country_values, force: true do |t|
      t.string :country, null: false, index: :unique

      t.timestamps null: false
    end

    CustomField.where(:type => 'EasyLeadScoreCustomField').update_all(:type => 'EasyCrmCountryValueCustomField')

    add_column(:easy_crm_cases, :lead_value, :integer, {:null => true}) unless column_exists?(:easy_crm_cases, :lead_value)
    add_column(:easy_crm_cases, :probability, :integer, {:null => true}) unless column_exists?(:easy_crm_cases, :probability)
  end

  def self.down
    drop_table(:easy_crm_country_values)
  end
end
