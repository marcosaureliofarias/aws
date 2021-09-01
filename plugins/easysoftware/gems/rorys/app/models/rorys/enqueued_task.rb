# frozen_string_literal: true

module Rorys
  ##
  # Content of the table is deleted after every restart
  # See bottom of the file
  #
  class EnqueuedTask < ActiveRecord::Base
    self.table_name = 'rorys_enqueued_tasks'

    # enum status: [:waiting, :running, :finished, :failed]

    serialize :data, JSON
    serialize :executions, JSON
  end
end
