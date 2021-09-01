class OldPassword < ActiveRecord::Base

  belongs_to :user

  scope :last_used, -> { order({ created_at: :desc, id: :desc }).limit(EasySetting.value('unique_password_counter').to_i) }

  validates_presence_of :user

end
