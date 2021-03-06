module EasyJob
  module TenantWrapper

    def initialize(*args)
      super
      @current_tenant = Apartment::Tenant.current
    end

    def ensure_redmine_env(*args)
      Apartment::Tenant.switch(@current_tenant){ super }
    end

  end
end

EasyJob::TaskWrapper.prepend(EasyJob::TenantWrapper)
