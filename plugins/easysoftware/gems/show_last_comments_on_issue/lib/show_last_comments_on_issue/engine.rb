require 'rys'

module ShowLastCommentsOnIssue
  class Engine < ::Rails::Engine
    include Rys::EngineExtensions

    initializer 'show_last_comments_on_issue.setup' do
      # Custom initializer
      EasySetting.map do
        key :issue_last_comments_limit do
          default 5
          from_params proc { |value| value.to_i }
        end
      end
    end

  end
end
