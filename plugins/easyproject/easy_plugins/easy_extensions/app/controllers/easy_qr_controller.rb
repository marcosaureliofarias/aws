class EasyQrController < ApplicationController

  def generate
    img = EasyQr.generate_image(params[:t], { :size => params[:size] })

    send_data img, type: 'image/png', disposition: 'inline'
  end

end
