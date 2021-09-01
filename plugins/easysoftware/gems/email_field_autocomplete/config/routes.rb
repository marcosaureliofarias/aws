Rails.application.routes.draw do

  rys_feature 'email_field_autocomplete' do
    get 'email_field_autocomplete/find', to: 'email_field_autocomplete#find', as: 'find_email_field_autocomplete'
  end

end
