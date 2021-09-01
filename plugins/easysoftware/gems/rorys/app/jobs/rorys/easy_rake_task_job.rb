# frozen_string_literal: true

module Rorys
  class EasyRakeTaskJob < Rorys.task
    queue_as :easy_rake_tasks

    def perform(task_klass, task_id)
      task_klass = task_klass.constantize
      task = task_klass.find(task_id)

      log_info(task, "is executing") do
        task_klass.execute_task(task)
      end
    ensure
      task&.update_column(:blocked_at, nil)
    end

    def log_info(task, message, &block)
      super "#{task.class} (ID=#{task.id}) #{message}", &block
    end

  end
end
