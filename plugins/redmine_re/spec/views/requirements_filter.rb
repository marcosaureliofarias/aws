require_relative '_requirements'

describe 'requirements/_filter.html.erb', type: :view do

  include_examples :requirements

  it 'renders filter' do
    render partial: 'requirements/filter'

    expect(rendered).to match(/id="treefilter"/)
    expect(rendered).to match(/source\[name_mode\]/)
  end
end