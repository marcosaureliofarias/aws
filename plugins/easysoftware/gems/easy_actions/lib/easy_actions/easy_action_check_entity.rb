module EasyActions
  module EasyActionCheckEntity
    extend ActiveSupport::Concern

    included do

      has_many :easy_action_checks, as: :entity, class_name: 'EasyActionCheck', dependent: :destroy

    end

    class_methods do
    end

  end
end
