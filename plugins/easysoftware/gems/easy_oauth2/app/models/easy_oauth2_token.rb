class EasyOauth2Token < ActiveRecord::Base

  belongs_to :entity, polymorphic: true

  validates :key, :value, presence: true

  def self.access_token(entity)
    where(entity: entity, key: 'access_token').first_or_initialize
  end

  def self.refresh_token(entity)
    where(entity: entity, key: 'refresh_token').first_or_initialize
  end

  def name
    key
  end


end
