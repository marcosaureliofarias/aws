class EasyShortUrlAccess < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :short_url, :class_name => "EasyShortUrl", :foreign_key => "easy_short_url_id"
  belongs_to :user

  safe_attributes 'user_id', 'ip', 'count'

end
