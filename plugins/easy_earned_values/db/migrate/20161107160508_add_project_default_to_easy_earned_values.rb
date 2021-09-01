class AddProjectDefaultToEasyEarnedValues < ActiveRecord::Migration[4.2]

  def change
    add_column :easy_earned_values, :project_default, :boolean, default: false
  end

end
