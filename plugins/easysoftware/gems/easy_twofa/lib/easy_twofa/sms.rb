require 'net/http'

module EasyTwofa
  ##
  # EasyTwofa::Sms
  #
  class Sms < Auth

    mattr_accessor :provider_handlers
    self.provider_handlers = {

      custom: lambda { |url, recipient, body|
        Net::HTTP.get(URI('http://www.example.com/index.html'))
      }

    }.with_indifferent_access

    def self.scheme_key
      :sms
    end

    def self.setting_partial_path
      'easy_twofa/sms/setting'
    end

    def self.default_messagebird_originator
      Setting.app_title.slice(0, 7)
    end

    def enable_resending?
      true
    end

    def prepare_verification
      @last_verification_status = VerificationStatus.new

      provider = setting['provider']
      provider_send_method = "send_via_#{provider}"
      provider_check_method = "check_for_#{provider}"

      if !provider || !respond_to?(provider_send_method, true)
        @last_verification_status.errors << I18n.t('easy_twofa.schemes.sms.errors.missing_provider')
        return
      end

      if respond_to?(provider_check_method, true) && !send(provider_check_method)
        @last_verification_status.errors << I18n.t('easy_twofa.schemes.sms.errors.provider_setting')
        return
      end

      telephone = @user.custom_value_for(setting['telephone_cf'])&.value

      if telephone.blank?
        @last_verification_status.errors << I18n.t('easy_twofa.schemes.sms.errors.missing_telephone')
        return
      end

      telephone = telephone.gsub(/\s/, '')

      user_scheme.sms_pass = SecureRandom.hex(5).slice(0, 9)
      user_scheme.sms_pass_created_at = Time.now
      user_scheme.save

      body = "Verify code: #{user_scheme.sms_pass.scan(/.{3}/).join('-')}"

      send(provider_send_method, telephone, body)
    end

    def setting
      EasySetting.value(:easy_twofa_sms)
    end

    def check_for_custom
      setting['custom_url'].present?
    end

    def send_via_custom(telephone, body)
      custom_url = setting['custom_url'].dup
      custom_url.gsub!('%{telephone}', telephone)
      custom_url.gsub!('%{body}', body)

      uri = URI(custom_url)

      if setting['custom_method'] == 'POST'
        response = Net::HTTP.post_form(uri, '')
      else
        response = Net::HTTP.get_response(uri)
      end

      response.is_a?(Net::HTTPSuccess)
    end

    def check_for_messagebird
      setting['messagebird_access_key'].present?
    end

    def send_via_messagebird(telephone, body)
      uri = URI('https://rest.messagebird.com/messages')

      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "AccessKey #{setting['messagebird_access_key']}"
      request['Accept'] = 'application/json'
      request['User-Agent'] = "EasyTwofa/#{EasyTwofa::VERSION}"
      request.set_form_data(
        recipients: telephone,
        originator: (setting['messagebird_originator'].presence || Sms.default_messagebird_originator),
        body: body
      )

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) {|http|
        http.request(request)
      }

      response.is_a?(Net::HTTPSuccess)
    end

    DRIFT = 30.minutes

    def verify!(verify_code, **options)
      verify_code = verify_code.to_s.gsub(/\W/, '')

      if user_scheme.sms_pass &&
         user_scheme.sms_pass_created_at &&
         user_scheme.sms_pass_created_at > (Time.now - DRIFT) &&
         user_scheme.sms_pass == verify_code

        user_scheme.sms_pass = nil
        user_scheme.sms_pass_created_at = nil
        user_scheme.save

        true
      else
        false
      end
    end

  end
end

EasyTwofa::Sms.register!
