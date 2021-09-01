class MoveAllEasyTodos < ActiveRecord::Migration[4.2]
  def self.up

    User.all.each do |user|
      user_lists = EasyToDoList.where(:user_id => user.id).sorted
      if user_lists.empty?
        l = (user.language.present? && user.language.to_sym.in?(I18n.available_locales) ? user.language : 'en' )
        EasyToDoList.create(:user_id => user.id, :name => I18n.t(:heading_easy_to_do_list, :locale => l))
      end

      if user_lists.count > 1
        first_list = user_lists.first

        (user_lists.all - [first_list]).each do |list|
          list.easy_to_do_list_items.each do |item|
            item.easy_to_do_list_id = first_list.id
            item.save!
          end
          list.reload.destroy
        end
      end

    end

  end

  def self.down

  end
end
