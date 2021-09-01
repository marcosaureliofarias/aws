Rys::Patcher.add('ApplicationHelper') do

  included do

    def user_lock_l(key, options={})
      l("security_user_lock.#{key}", options)
    end

  end

end
