class EasyPagePermission < ActiveRecord::Base

  belongs_to :entity, polymorphic: true
  belongs_to :easy_page

  enum permission_type: [:show, :edit], _prefix: :permission

end
