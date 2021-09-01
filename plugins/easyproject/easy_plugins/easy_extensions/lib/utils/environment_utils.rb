# Based on Newrelic code
module EasyUtils
  module EnvironmentUtils
    extend self

    def running_in_regular_process?
      !Rails.env.test? && !blacklisted_constants? && !blacklisted_executables? && !in_blacklisted_rake_task?
    end

    def blacklisted_constants?
      blacklisted?('Rails::Console') do |name|
        constant_is_defined?(name)
      end
    end

    def blacklisted_executables?
      blacklisted?('irb,rspec') do |bin|
        File.basename($0) == bin
      end
    end

    def blacklisted?(value, &block)
      value.split(/\s*,\s*/).any?(&block)
    end

    def constant_is_defined?(const_name)
      const_name.to_s.sub(/\A::/, '').split('::').inject(Object) do |namespace, name|
        begin
          result = namespace.const_get(name)

          if result.is_a?(Module)
            expected_name = "#{namespace}::#{name}".gsub(/^Object::/, "")
            return false unless expected_name == result.to_s
          end

          result
        rescue NameError
          false
        end
      end
    end

    def in_blacklisted_rake_task?
      tasks = begin
        ::Rake.application.top_level_tasks
      rescue => e
        []
      end
      !(tasks & 'about,assets:clean,assets:clobber,assets:environment,assets:precompile,assets:precompile:all,db:create,db:drop,db:fixtures:load,db:migrate,db:migrate:status,db:rollback,db:schema:cache:clear,db:schema:cache:dump,db:schema:dump,db:schema:load,db:seed,db:setup,db:structure:dump,db:version,doc:app,log:clear,middleware,notes,notes:custom,rails:template,rails:update,routes,secret,spec,spec:features,spec:requests,spec:controllers,spec:helpers,spec:models,spec:views,spec:routing,spec:rcov,stats,test,test:all,test:all:db,test:recent,test:single,test:uncommitted,time:zones:all,tmp:clear,tmp:create,easyproject:install,easyproject:uninstall,easyproject:scheduler:run'.split(/\s*,\s*/)).empty?
    end

  end
end
