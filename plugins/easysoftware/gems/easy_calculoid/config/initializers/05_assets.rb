# Assets definitions
# https://guides.rubyonrails.org/asset_pipeline.html
#
Rails.application.configure do
  config.assets.precompile << "easy_calculoid/easy_calculoid.js"
end
