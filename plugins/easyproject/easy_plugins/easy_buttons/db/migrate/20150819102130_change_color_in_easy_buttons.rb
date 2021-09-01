class ChangeColorInEasyButtons < ActiveRecord::Migration[4.2]
  def change
    remove_column :easy_buttons, :background, :string
    remove_column :easy_buttons, :font_color, :string

    # Pallete
    add_column :easy_buttons, :color, :string
  end
end
