require 'easy_extensions/spec_helper'

describe NewsController, :logged => :admin do
  let(:project) { FactoryGirl.create(:project, :members => [User.current], :enabled_module_names => ['news']) }

  render_views

  it 'render news' do
    ['HTML', 'textile', 'markdown'].each do |f|
      with_settings({ 'text_formatting' => f }) do
        get :index, :params => { :project_id => project.id }
        expect(response).to be_successful
      end
    end
  end
end
