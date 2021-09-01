Rails.application.routes.draw do
  rys_feature 'easy_computed_field_from_query' do
    get 'easy_contacts/:id/recalculate_cf', to: 'easy_contacts#recalculate_cf', as: 'recalculate_cf_easy_contact'
  end
end
