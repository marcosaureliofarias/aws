require_relative '_requirements'

describe 'requirements/index.html.erb', type: :view do

  include_examples :requirements

  it 'renders index' do
    render template: 'requirements/index'

    expect(rendered).to match(/id="infobar"/)
    expect(rendered).to match(/id="re-index"/)
  end
end