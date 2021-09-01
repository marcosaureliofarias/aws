module Ryspec::Test
  module Users

    def with_user_pref(options, &block)
      user = User.current
      pref = user.pref

      saved_settings = options.each_with_object({}) do |(key, value), memo|
        old_value = pref.send(key)
        memo[key] = case value
                    when Symbol, false, true, nil
                      value
                    else
                      value.dup
                    end
      end

      options.each {|key, value| pref.send("#{key}=", value) }
      pref.save

      yield
    ensure
      saved_settings.each {|key, value| pref.send("#{key}=", value) }
      pref.save
    end

    # Yields the block with user as the current user
    def with_current_user(user, &block)
      saved_user = User.current
      allow(User).to receive(:current).and_return(user)
      yield
    ensure
      logged_user(saved_user)
    end

    def logged_user(user)
      allow(User).to receive(:current).and_return(user)
    end

  end
end
