require_relative "../spec_helper"
require_relative '_settings_form'

describe 're_settings/edit.html.erb', type: :view do
  include_examples :settings_form, 'edit'
end
