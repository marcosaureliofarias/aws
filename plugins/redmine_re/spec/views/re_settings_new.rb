require_relative "../spec_helper"
require_relative '_settings_form'

describe 're_settings/new.html.erb', type: :view do
  include_examples :settings_form, 'new'
end