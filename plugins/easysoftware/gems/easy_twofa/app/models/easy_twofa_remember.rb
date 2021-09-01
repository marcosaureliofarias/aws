# frozen_string_literal: true

require 'ipaddr'

class EasyTwofaRemember < ActiveRecord::Base

  store :device, accessors: [:user_agent, :ip, :address]

  belongs_to :user_scheme, class_name: 'EasyTwofaUserScheme', foreign_key: 'easy_twofa_user_scheme_id'

  scope :ordered, lambda { order(expired_at: :desc, id: :desc) }
  scope :expired, lambda { where('expired_at < ?', Date.today)  }
  scope :not_expired, lambda { where('expired_at >= ?', Date.today)  }

  validates_presence_of :expired_at, :device

  def self.remember_device(scheme, request)
    # Just in case
    if scheme.user_scheme.new_record?
      return
    end

    remember = scheme.user_scheme.remembers.build(
      expired_at: (Date.today + EasyTwofa.config.remember_for),
      ip: request.remote_ip,
      user_agent: request.user_agent,
    )

    if remember.save
      begin
        ipaddr = IPAddr.new(remember.ip)

        if !private_address?(ipaddr)
          EasyTwofa::GetRememberLocation.perform_later(remember)
        end
      rescue IPAddr::InvalidAddressError
      end
    end
  end

  def device_match?(request)
    ip == request.remote_ip && user_agent == request.user_agent
  end

  if IPAddr.new.respond_to?(:private?)
    def self.private_address?(ipaddr)
      ipaddr.private? # ruby 2.5+
    end
  else
    def self.private_address?(ipaddr)
      case ipaddr.family
      when Socket::AF_INET
        ipaddr & 0xff000000 == 0x0a000000 ||    # 10.0.0.0/8
        ipaddr & 0xfff00000 == 0xac100000 ||  # 172.16.0.0/12
        ipaddr & 0xffff0000 == 0xc0a80000     # 192.168.0.0/16
      when Socket::AF_INET6
        ipaddr & 0xfe00_0000_0000_0000_0000_0000_0000_0000 == 0xfc00_0000_0000_0000_0000_0000_0000_0000
      else
        raise IPAddr::AddressFamilyError, "unsupported address family"
      end
    end
  end

end
