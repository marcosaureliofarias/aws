require 'net/http'
require 'net/https'
require 'uri'

module EasyUtils
  class HttpUtils

    def self.url_invalid?(domain_url, path = nil)
      begin
        get_request(domain_url, path)
      rescue SocketError => ex
        msg = ex.message
        msg.force_encoding('UTF-8') if msg.respond_to?(:force_encoding)
        return msg
      end

      return nil
    end

    def self.get_request(domain_url, path = nil, options = {}, &block)
      raise Net::HTTPError.new('Too many redirects', nil) if options[:redirect_count].to_i > 3
      http, relative_url = prepare_http_and_relative_url(domain_url, path, options)
      request            = Net::HTTP::Get.new(relative_url)

      if options[:basic_user] && options[:basic_password]
        request.basic_auth(options[:basic_user], options[:basic_password])
      end
      if block_given?
        yield request, http
      end

      response = http.request(request)

      if options[:follow_redirect] && response && ['301', '302'].include?(response.code) && (new_url = response.header['location']) && !new_url.blank?
        options[:redirect_count] ||= 0
        options[:redirect_count] += 1
        return get_request(new_url, nil, options)
      end

      response
    end

    def self.post_request(domain_url, path = nil, options = {}, &block)
      http, relative_url = prepare_http_and_relative_url(domain_url, path, options)

      request = Net::HTTP::Post.new(relative_url)
      request.set_form_data(options[:form_data]) if options[:form_data]
      if block_given?
        yield request, http
      end

      if options[:basic_user] && options[:basic_password]
        request.basic_auth(options[:basic_user], options[:basic_password])
      end

      response = http.request(request)

      response
    end

    def self.prepare_http_and_relative_url(domain_url, path = nil, options = {})
      if domain_url.is_a?(URI)
        uri = domain_url
      else
        uri = URI.parse(domain_url)
      end
      http = Net::HTTP.new(uri.host, uri.port)

      if uri.port == 443 || uri.scheme == 'https'
        http.use_ssl     = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      if uri.userinfo
        username, password       = uri.userinfo.to_s.split(':')
        options[:basic_user]     ||= username
        options[:basic_password] ||= password
      end

      relative_url = path

      if path.nil? && uri.path
        relative_url = uri.path
        relative_url = "#{relative_url}?#{uri.query}" unless uri.query.blank?
        relative_url = "#{relative_url}##{uri.fragment}" unless uri.fragment.blank?
      elsif path && uri.path && path.start_with?('#')
        relative_url = "#{uri.path}#{path}"
      end

      relative_url ||= path || uri.path
      relative_url = '/' if relative_url.blank?

      return [http, relative_url]
    end

    def self.get_request_body(domain_url, path = nil, options = {})
      begin
        response = get_request(domain_url, path, options)
      rescue Exception => e
        Rails.logger.error e.message
      end

      if response
        response.body
      else
        nil
      end
    end

    def self.post_request_body(domain_url, path = nil, options = {})
      response = post_request(domain_url, path, options)

      if response
        response.body
      else
        nil
      end
    end

    def self.post_xml(url, xml)
      uri                  = URI.parse(url)
      request              = Net::HTTP::Post.new(uri.path)
      request.body         = xml
      request.content_type = 'text/xml'
      Net::HTTP.start(uri.host, uri.port) { |http| http.request(request) }
    end

  end
end
