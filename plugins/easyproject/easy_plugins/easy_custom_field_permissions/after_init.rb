ActiveSupport.on_load(:easyproject, yield: true) do

  require 'easy_custom_field_permissions/hooks'

end
