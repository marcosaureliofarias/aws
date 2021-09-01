module EasyActions
  module Actions
    class NewEmail < ::EasyActions::Actions::Base

      attr_accessor :subject, :to, :body

      validates :subject, :to, :body, presence: true

      def fire(entity)
        EasyActionStateActionMailer.new_email(self).deliver
      end

    end
  end
end
