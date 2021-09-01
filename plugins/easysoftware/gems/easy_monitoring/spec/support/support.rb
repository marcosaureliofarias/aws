# module EasyMonitoring::Test
#   module Helper
#   end
# end
RSpec.shared_context "configure metadata" do |**options|
  before do
    EasyMonitoring::Metadata.configure do |metadata|
      metadata.host_name = options.fetch(:host_name, 'your.site.domain')
      # you can also add more metadata like version or whatever
      metadata.version = options.fetch(:version, '1.2.3')
      # metadata.weather = 'Always sunny'
    end
  end
end