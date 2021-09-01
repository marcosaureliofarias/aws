Rys::Patcher.add('Issue') do

  apply_if_plugins :easy_extensions

  included do

    include EasyActions::EasyActionSequenceEntity
    include EasyActions::EasyActionSequenceInstanceEntity

  end

end
