ActiveSupport.on_load(:easyproject, yield: true) do
  require 'html_formatting/internals'
  require 'html_formatting/formatter'
  require 'html_formatting/helper'

  Redmine::WikiFormatting.register(:HTML, EasyPatch::HTMLFormatting::Formatter, EasyPatch::HTMLFormatting::Helper)
end
