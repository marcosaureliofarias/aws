Rys::Patcher.add('Project') do

  included do
    has_one :easy_jenkins_setting, class_name: 'EasyJenkins::Setting'
  end

  instance_methods do
  end

  instance_methods(feature: 'easy_jenkins.project') do
  end

  class_methods do
  end

end
