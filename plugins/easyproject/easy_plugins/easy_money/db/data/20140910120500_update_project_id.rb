class UpdateProjectId < ActiveRecord::Migration[4.2]

  EASY_MONEY_TABLE_NAMES = [:easy_money_expected_revenues, :easy_money_expected_expenses,
    :easy_money_other_revenues, :easy_money_other_expenses, :easy_money_expected_payroll_expenses]
  EASY_MONEY_MODELS = EASY_MONEY_TABLE_NAMES.map{|t| t.to_s.classify.constantize}

  def up
    EASY_MONEY_MODELS.each do |m|
      m.find_each(:batch_size => 50) do |m|
        m.update_column(:project_id, m.project_from_entity.id) if m.project_from_entity
      end
    end
  end

  def down
  end
end
