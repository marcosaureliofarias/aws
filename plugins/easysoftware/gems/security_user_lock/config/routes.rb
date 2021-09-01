Rails.application.routes.draw do

  rys_feature 'security_user_lock' do
    patch 'users/:id/unblock', to: 'users#unblock', as: 'unblock_user'
  end

end
