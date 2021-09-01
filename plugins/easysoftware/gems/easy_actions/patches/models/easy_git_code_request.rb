Rys::Patcher.add('EasyGitCodeRequest') do

  apply_if_plugins :easy_extensions
  apply_if_rysy :easy_git

  included do

    include EasyActions::EasyActionSequenceInstanceEntity
    include EasyActions::EasyActionCheckEntity

  end

end
