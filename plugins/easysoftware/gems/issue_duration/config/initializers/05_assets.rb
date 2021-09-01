# Assets definitions
# https://guides.rubyonrails.org/asset_pipeline.html
#
Rails.application.configure do
  config.assets.precompile << 'issue_duration/issue_easy_duration.js'
end
