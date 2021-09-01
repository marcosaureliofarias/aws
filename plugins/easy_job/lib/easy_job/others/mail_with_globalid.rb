#
# Temporary patch for issue #183084 and #208085
#
# Sometimes email job works with strange issue instance.
# For example tracker is nil when it isn't.
#
# Solution: save instance reference instead issue itself.
#

module EasyJob
  module MailWithGlobalid
    module MessageDeliveryPatch

      def easy_deliver
        return if !ActionMailer::Base.perform_deliveries

        @args.map! do |arg|
          if arg.is_a?(GlobalID::Identification)
            arg.to_global_id
          else
            arg
          end
        end

        super
      end

    end
  end
end

module EasyJob
  module MailWithGlobalid
    module MailerTaskPatch

      def perform(message)
        message.instance_variable_get(:@args).map! do |arg|
          if arg.is_a?(GlobalID)
            arg.find
          else
            arg
          end
        end

        super
      end

    end
  end
end

if !Rails.env.test?
  ActionMailer::MessageDelivery.prepend(EasyJob::MailWithGlobalid::MessageDeliveryPatch)
  EasyJob::MailerTask.prepend(EasyJob::MailWithGlobalid::MailerTaskPatch)
end
