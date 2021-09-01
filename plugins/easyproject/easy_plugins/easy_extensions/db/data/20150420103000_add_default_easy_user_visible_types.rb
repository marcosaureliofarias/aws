class AddDefaultEasyUserVisibleTypes < ActiveRecord::Migration[4.2]
  def up
    all_types = EasyUserType.where(nil).to_a
    all_types.each do |type|
      all_types.each do |t|
        type.easy_user_visible_types << t unless type.easy_user_visible_types.include?(t)
      end
    end
  end

  def down
    EasyUserType.find_each(:batch_size => 50) do |easy_user_type|
      easy_user_type.easy_user_visible_types.delete_all
    end
  end
end
