Rys::Patcher.add('User') do

  included do
    has_one :easy_twofa_scheme, class_name: 'EasyTwofaUserScheme', foreign_key: 'user_id'
  end

  instance_methods do

    def easy_twofa_active?
      !!easy_twofa_scheme&.fully_activated?
    end

  end

end
