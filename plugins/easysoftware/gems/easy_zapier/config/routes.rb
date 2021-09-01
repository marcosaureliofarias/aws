Rails.application.routes.draw do

  rys_feature 'easy_zapier' do
    get 'zapier_integration', to: 'easy_zapier#templates_overview', as: 'easy_zapier_integration'
  end

end
