require 'geocoder'

class GetContactGeocodeJob < EasyActiveJob
  queue_as :default

  def perform(easy_contact_id)
    easy_contact = EasyContact.find(easy_contact_id)

    begin
      coord = Geocoder.coordinates(easy_contact.address) if easy_contact.address.present?
      coord ||= Geocoder.coordinates(easy_contact.street) if easy_contact.street.present?
      easy_contact.update_columns(latitude: coord[0], longitude: coord[1]) if coord

    rescue Geocoder::NetworkError
      raise ::EasyActiveJob::RetryException
    end
  end

end
