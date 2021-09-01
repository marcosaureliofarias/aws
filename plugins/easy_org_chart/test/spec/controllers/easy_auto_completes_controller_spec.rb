require 'easy_extensions/spec_helper'

describe EasyAutoCompletesController do
  it 'with subordinates', logged: :admin do
    get :index, params: { autocomplete_action: 'internal_users', include_peoples: 'me,subordinates', format: 'json' }
    expect(assigns[:additional_options].map(&:last)).to match_array(['me', 'my_subordinates', 'my_subordinates_tree'])
  end

  include_examples 'include_subordinates', 'additional_options', 'internal_users'
  include_examples 'include_subordinates', 'additional_options', 'principals'
  include_examples 'include_subordinates', 'additional_select_options', 'visible_principals', {"<< #{I18n.t(:label_me)} >>" => 'me'} do |additional_select_options|
    additional_select_options.to_a
  end
end
