# frozen_string_literal: true

module Rorys
  class QueueEasyRakeTasksJob < Rorys.task
    queue_as :easy_rake_tasks

    def perform
      raise "You shall not pass!" # Temporary

      tasks = EasyRakeTask.scheduled
      tasks.each do |task|
        task.update_column(:blocked_at, Time.now)
        Rorys::EasyRakeTaskJob.perform_later(task.class.name, task.id)

        log_info "#{task.class} (ID=#{task.id}) was queued"
      end
    end

  end
end
