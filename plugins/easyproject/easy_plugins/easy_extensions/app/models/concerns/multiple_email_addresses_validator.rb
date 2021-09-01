class MultipleEmailAddressesValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    return unless value.present?
    
    addresses = value.to_s.split(/[,\r\n]/).map(&:strip).select(&:present?)
    addresses.each do |address|
      unless (addr_parts = address.match(/^(?:"?([^"]*)"?\s)?(?:<?(.+@[^>]+)>?)$/)) && addr_parts[2] && EmailAddress::EMAIL_REGEXP.match?(addr_parts[2])
        record.errors.add attribute, I18n.t(:error_email_address_format_invalid, address: address)
      end
    end

    unless record.errors[attribute].any?
      record.send("#{attribute}=", addresses.join(', '))
    end
  end

end