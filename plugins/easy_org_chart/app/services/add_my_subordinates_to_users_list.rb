class AddMySubordinatesToUsersList
  include Redmine::I18n

  def self.call(users)
    me_position = users.index{|value| value.last == 'me'}.presence || -1
    users.insert(me_position + 1, ["<< #{l(:label_my_subordinates)} >>", 'my_subordinates'])
    users.insert(me_position + 2, ["<< #{l(:label_my_subordinates_tree)} >>", 'my_subordinates_tree'])
  end
end
