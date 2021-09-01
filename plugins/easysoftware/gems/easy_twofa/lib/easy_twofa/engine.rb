require 'rys'

module EasyTwofa
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    lib_dependency_files do
      [
        'easy_twofa/auth',
        'easy_twofa/totp',
        'easy_twofa/sms',
        'easy_twofa/verification_status',
        'easy_twofa/ciphered_json',
      ]
    end

    initializer 'easy_twofa.setup' do |app|
      app.config.assets.precompile << 'easy_twofa.css'
    end

  end
end
