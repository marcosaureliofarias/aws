class EasyOauth2ApplicationUserAuthorization < ActiveRecord::Base

  belongs_to :easy_oauth2_application
  belongs_to :user

  validates :code, presence: true

end
