require 'easy_extensions/spec_helper'

describe MyController, :logged => :admin do
  def prepare_page
    page      = EasyPage.find_by(page_name: 'my-page')
    tab       = EasyPageUserTab.create(:page_id => page.id, :user_id => User.current.id, :name => 'my tab')
    az        = EasyPageAvailableZone.first
    zone_name = az.zone_definition.zone_name
    am        = EasyPageAvailableModule.first
    epzm      = EasyPageZoneModule.create(:easy_pages_id => page.id, :user_id => User.current.id, :tab_id => tab.id, :easy_page_available_zones_id => az.id, :easy_page_available_modules_id => am.id)
    { :epzm => epzm, :zone_name => zone_name }
  end

  it 'index redirect' do
    get :index
    expect(response).to be_successful
  end

  it 'set page modules data' do
    page_def = prepare_page
    get :page
    expect(assigns(:easy_page_modules_data)).not_to be_blank
    expect(assigns(:__easy_page_ctx)[:page_modules][page_def[:zone_name]].first).to eq page_def[:epzm]
  end

  it 'load modules from the first tab if desired tab doesnt exist' do
    page_def = prepare_page
    get :page, :params => { :t => EasyPageUserTab.last.id + 1 }
    expect(assigns(:easy_page_modules_data)).not_to be_blank
    expect(assigns(:__easy_page_ctx)[:page_modules][page_def[:zone_name]].first).to eq page_def[:epzm]
  end

end
