# Be careful !!!
# This adapter works only for Rails 4

module ActiveJob
  module QueueAdapters
    class EasyJobAdapter

      def self.enqueue(job)
        JobWrapper.perform_async(job.serialize)
      end

      def self.enqueue_at(job, timestamp)
        interval = timestamp - Time.current.to_f
        if interval > 0
          JobWrapper.perform_in(job.serialize, interval: interval)
        else
          JobWrapper.perform_async(job.serialize)
        end
      end

      class JobWrapper < EasyJob::Task

        def perform(job_data)
          Base.execute(job_data)
        end

      end

    end
  end
end
