class EasyIntegrationLog < ActiveRecord::Base

  belongs_to :easy_integration
  belongs_to :entity, polymorphic: true

  enum status: { idle: 0, done: 5, failed: 9 }

end
