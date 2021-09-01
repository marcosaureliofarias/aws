module EasyUserTypesHelper

  def easy_user_types_for_select
    select_options = [["<< #{l(:general_all)} >>", 'all']]
    select_options.concat(EasyUserType.sorted.map { |type| [type.name, type.id] })
    select_options
  end

end
