resource :easy_org_chart, only: [:show, :create], controller: 'easy_org_chart' do
  get :tree, :users
end
