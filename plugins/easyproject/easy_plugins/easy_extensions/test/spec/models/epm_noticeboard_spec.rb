require 'easy_extensions/spec_helper'

describe EpmNoticeboard, logged: :admin do
  it 'xss' do
    with_settings({ 'text_formatting' => 'HTML' }) do
      epzm          = EasyPageZoneModule.new
      epzm.settings = { 'text' => "<script>alert('xss')</script><p>something</p>" }
      EpmNoticeboard.new.page_zone_module_before_save(epzm)
      expect(epzm.settings['text']).to eq("alert('xss')<p>something</p>")
    end
  end
end
