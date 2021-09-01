class AfterDateValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    with_attribute = options.fetch(:with)
    other_date = record.public_send(with_attribute)

    return if other_date.blank?

    if value < other_date
      record.errors.add(attribute, options[:message] || I18n.t("#{attribute}_greater_than_#{with_attribute}_error", default: "would be before #{with_attribute.to_s.humanize}, please set correct date."))
    end
  end
end
