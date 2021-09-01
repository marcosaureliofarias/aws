Rys::Patcher.add('User') do

  apply_if_plugins :easy_extensions

  included do

    has_many :easy_oauth2_authentications, foreign_key: 'user_id', dependent: :delete_all
    has_many :easy_oauth2_access_grants, foreign_key: 'user_id', dependent: :delete_all

  end

end
