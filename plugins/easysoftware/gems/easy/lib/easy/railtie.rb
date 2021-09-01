module Easy
  class Railtie < ::Rails::Railtie

    config.to_prepare do
      ::ApplicationHelper.include ::Easy::Patches::ApplicationHelper
    end

  end
end
