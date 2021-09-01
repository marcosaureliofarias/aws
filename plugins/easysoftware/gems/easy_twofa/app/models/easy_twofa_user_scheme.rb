# frozen_string_literal: true

class EasyTwofaUserScheme < ActiveRecord::Base

  belongs_to :user
  has_many :remembers, class_name: 'EasyTwofaRemember', foreign_key: 'easy_twofa_user_scheme_id', dependent: :destroy

  store :settings, accessors: [:totp_key, :totp_last_used_at, :sms_pass, :sms_pass_created_at], coder: EasyTwofa::CipheredJSON

  def fully_activated?
    activated? && EasyTwofa::Auth.enabled_schemes.has_key?(scheme_key)
  end

end
