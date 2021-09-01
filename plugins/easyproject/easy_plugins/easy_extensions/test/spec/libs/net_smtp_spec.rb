RSpec.describe Net::SMTP do

  context 'SNI support' do

    it 'uses the address as the hostname for SNI if setting hostname is supported' do
      allow_any_instance_of(OpenSSL::SSL::SSLSocket).to receive(:hostname=)
      expect_any_instance_of(OpenSSL::SSL::SSLSocket).to receive(:hostname=).with("address")
      socket = instance_double("TCPSocket")
      expect(socket).to receive(:sync)
      Net::SMTP.new("address").__send__(:ssl_socket, socket, OpenSSL::SSL::SSLContext.new)
    end

    it 'does not set SNI hostname if it is not supported' do
      allow_any_instance_of(OpenSSL::SSL::SSLSocket).to receive(:respond_to?).with(:hostname=).and_return(false)
      expect_any_instance_of(OpenSSL::SSL::SSLSocket).not_to receive(:hostname=)
      socket = instance_double("TCPSocket")
      expect(socket).to receive(:sync)
      Net::SMTP.new("address").__send__(:ssl_socket, socket, OpenSSL::SSL::SSLContext.new)
    end

  end

end