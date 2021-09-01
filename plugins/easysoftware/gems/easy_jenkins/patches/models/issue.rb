Rys::Patcher.add('Issue') do

  included do
    before_save :run_easy_jenkins_pipelines, if: :status_id_changed?
  end

  instance_methods do
    def run_easy_jenkins_pipelines
      pipelines = EasyJenkins::Pipeline.for_issue(self, self.project).for_status(status).distinct

      pipelines.each do |pipeline|
        EasyJenkins::Api::Request.call(setting: pipeline.setting).run_job(pipeline, self)
      end
    end
  end

  class_methods do
  end

end
