module EasyJob
  module ExceptionsNotifier

    def handle_error(job, ex)
      super

      # Backtrace can be frozen
      backtrace = ex.backtrace + @task_caller.map(&:to_s)
      ex.set_backtrace(backtrace)

      EasyExtensions::ExceptionsNotifier.notify(ex)
    end

  end
end

EasyJob::TaskWrapper.prepend(EasyJob::ExceptionsNotifier)
