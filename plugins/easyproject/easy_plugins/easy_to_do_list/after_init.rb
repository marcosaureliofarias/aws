ActiveSupport.on_load(:easyproject, yield: true) do
  require 'easy_to_do_list/hooks'
  require 'easy_to_do_list/menus'
  require 'easy_to_do_list/permissions'
end
