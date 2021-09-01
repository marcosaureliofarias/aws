class EasyJenkins::Api::Connection
  def api
    Faraday.new(setting.url) do |connection|
      connection.basic_auth(setting.user_name, setting.user_token)
      connection.adapter Faraday.default_adapter
    end
  end

  def fetch_response(url, method = :get)
    begin
      response = api.send(method, url)

      ApiResponse.new(response[:location], parse_json(response.body))
    rescue Faraday::Error => e
      ApiResponse.new(401, {})
    end
  end

  def parse_json(json)
    return {} if json.presence.nil?

    JSON.parse(json)
  end

  class ApiResponse < Struct.new(:location, :body)
    def queue_id
      self.location.split('/').last if self.location.present?
    end

    def status
      self.location
    end
  end

  class BuildResponse < Struct.new(:name, :result, :duration, :url)
    def to_s
      I18n.t('easy_jenkins.pipeline_finished_result', name: name, result: result, duration: duration_to_seconds)
    end

    def duration_to_seconds
      (self.duration.to_f / 1000).round(1)
    end
  end

  class Response < Struct.new(:note, :queue_id)
    def to_s
      I18n.t('easy_jenkins.queue_note', note: note, queue_id: queue_id)
    end
  end
end