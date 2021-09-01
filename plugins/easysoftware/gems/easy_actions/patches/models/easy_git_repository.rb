Rys::Patcher.add('EasyGitRepository') do

  apply_if_plugins :easy_extensions
  apply_if_rysy :easy_git

  included do

    include EasyActions::EasyActionSequenceEntity

  end

end
