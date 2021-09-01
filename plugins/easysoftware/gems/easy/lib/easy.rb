require "easy/railtie"

module Easy

  autoload :BasicEntity, "easy/basic_entity"

  module Errors
    autoload :Expected, "easy/errors/expected"
    autoload :DiscardJob, "easy/errors/discard_job"
    autoload :RetryJob, "easy/errors/retry_job"
    autoload :WorkerFailed, "easy/errors/worker_failed"
  end

  module Patches
    autoload :ApplicationHelper, "easy/patches/application_helper"
  end

  def self.hash_flatten(a_el, a_k = nil)
    result = {}

    a_el = a_el.as_json

    a_el.map do |k, v|
      k = "#{a_k}.#{k}" if a_k.present?
      result.merge!([Hash, Array].include?(v.class) ? hash_flatten(v, k) : ({ k => v }))
    end if a_el.is_a?(Hash)

    a_el.uniq.each_with_index do |o, i|
      i = "#{a_k}.#{i}" if a_k.present?
      result.merge!([Hash, Array].include?(o.class) ? hash_flatten(o, i) : ({ i => o }))
    end if a_el.is_a?(Array)

    result
  end
end
