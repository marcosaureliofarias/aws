# Assets definitions
# https://guides.rubyonrails.org/asset_pipeline.html

Rails.application.configure do
  config.assets.precompile << "easy_dagre_d3/dagre-d3.min.js"
  config.assets.precompile << "easy_dagre_d3/chart.css"
end
