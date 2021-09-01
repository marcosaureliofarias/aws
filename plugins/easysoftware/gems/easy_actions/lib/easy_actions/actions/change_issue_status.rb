module EasyActions
  module Actions
    class ChangeIssueStatus < ::EasyActions::Actions::Base

      attr_accessor :new_status_id

      validates :new_status_id, presence: true

      def fire(entity)
        return unless entity.respond_to?(:status_id)

        entity.status_id = new_status_id
        entity.save
      end

    end
  end
end
