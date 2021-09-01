require_relative '_requirements'

describe 'requirements/_treebar.html.erb', type: :view do

  include_examples :requirements

  it 'renders treebar' do
    render 'requirements/treebar'

    expect(rendered).to match(/id="treebar"/)
  end
end