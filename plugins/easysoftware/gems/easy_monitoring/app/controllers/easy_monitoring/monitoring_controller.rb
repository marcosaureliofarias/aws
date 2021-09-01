module EasyMonitoring
  class MonitoringController < ActionController::Base

    def monitoring
      respond_to do |format|
        format.html { render layout: false }
        format.xml { render xml: EasyMonitoring::Metadata.instance }
        format.json { render json: EasyMonitoring::Metadata.instance }
      end
    end

    def server_resources
      @memory = EasyMonitoring::ApplicationMemory.usage

      respond_to do |format|
        format.json do
          render json: { 'easy_web_application' => { 'memory' => @memory } }
        end
      end
    end

    def sidekiq
      ps      = Sidekiq::ProcessSet.new
      workers = Sidekiq::Workers.new
      running = !!Sidekiq.redis(&:info) rescue false

      render json: { 'process_size' => ps.size, 'workers_size' => workers.size, 'running' => running }
    end

  end
end
