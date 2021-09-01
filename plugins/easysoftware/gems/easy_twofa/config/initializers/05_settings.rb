EasySetting.map do

  key :easy_twofa_sms do
    default Hash.new
  end

  key :easy_twofa_mode do
    default 'optional'
  end

  key :easy_twofa_enabled_schemes do
    default Array.new
  end

end
