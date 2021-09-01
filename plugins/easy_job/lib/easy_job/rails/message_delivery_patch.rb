module EasyJob
  ##
  # ActionMailer::MessageDelivery
  #
  # It's a delegator which is created on method_missing.
  #
  module MessageDeliveryPatch

    def self.included(base)
      if Rails.env.test?
        base.include(TestInstanceMethods)
      else
        base.include(InstanceMethods)
      end
    end

    module InstanceMethods

      # Mail will be generated and sent later
      #
      #   Mailer.issue_add(issue, [], []).easy_deliver
      #
      def easy_deliver
        # `perform_deliveries` is class variable which affecting all
        # threads in current process so you cannot just set it in a job.
        return if !ActionMailer::Base.perform_deliveries
        EasyJob::MailerTask.perform_async(self)
      end

      # Mail is generated now and sent later
      #
      #   Mailer.issue_add(issue, [], []).easy_safe_deliver
      #
      def easy_safe_deliver
        # `perform_deliveries` is class variable which affecting all
        # threads in current process so you cannot just set it in a job.
        return if !ActionMailer::Base.perform_deliveries
        EasyJob::MailerTask.perform_async(message)
      end

    end

    module TestInstanceMethods

      def easy_deliver
        deliver
      end

      def easy_safe_deliver
        deliver
      end

    end

  end
end

ActionMailer::MessageDelivery.include(EasyJob::MessageDeliveryPatch)
