require 'rys'

module EasyGraphql
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    rys_id 'easy_graphql'

  end
end
