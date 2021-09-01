class EasyJenkins::PipelinesTracker < ApplicationRecord
  self.table_name = 'easy_jenkins_pipelines_trackers'

  belongs_to :pipeline, class_name: 'EasyJenkins::Pipeline'
  belongs_to :tracker
end
