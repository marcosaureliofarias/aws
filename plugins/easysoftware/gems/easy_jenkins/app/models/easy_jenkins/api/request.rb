class EasyJenkins::Api::Request < EasyJenkins::Api::Connection
  include EasyJenkins::Api::Callable

  attr_accessor :setting

  def initialize(setting:)
    @setting = setting
  end

  def call
    self
  end

  def fetch_jobs
    response = fetch_response('/api/json?tree=jobs[name]')

    response.body['jobs'].map { |job| [job['name'], job['name']] if job.is_a?(Hash) }
  end

  def run_job(pipeline, issue)
    response = fetch_response("/job/#{pipeline.external_name}/build", :post)

    pipeline.jobs.create(queue_id: response.queue_id, state: :pending, issue_ids: [issue.id])
  end

  def connected?
    response = fetch_response('/api/json?tree=jobs[name]')
    response.status != 401
  end
end