module EasyExtensions
  class ExternalResources::ExternalResourceBase < ActiveResource::Base

    def inspect
      "#<#{self.class.name} id=#{self.id}>"
    end

  end
end
