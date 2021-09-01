require_relative '../spec_helper'

describe ApplicationController do
  
  def ua(str)
    @request.stub(:user_agent).and_return(str)
  end

  it "mobile view" do
    ua "phone Mozilla/5.0 (Linux; Android 4.4.4; One Build/KTU84L.H4) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/33.0.0.0 Mobile Safari/537.36 [FB_IAB/FB4A;FBAV/28.0.0.20.16;]"
    expect(@controller.is_mobile_device?).to be true
    expect(@controller.in_mobile_view?).to be true
  end

end