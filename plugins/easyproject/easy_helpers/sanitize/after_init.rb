ActiveSupport.on_load(:easyproject, yield: true) do
  require 'sanitize'
end
