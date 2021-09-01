ActiveSupport.on_load(:easyproject, yield: true) do
  require 'before_render'
end
