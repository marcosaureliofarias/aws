require 'easy_extensions/external_resources/external_resource_base'

module EasyExtensions
  class ExternalResources::Fakturoid::FakturoidResourceBase < ExternalResources::ExternalResourceBase

    add_response_method :http_response

    def self.get_all_records(http_params = {}, &block)
      records_batch       = self.all(:params => http_params)
      first_batch_headers = records_batch.http_response.headers
      links_info          = (first_batch_headers[:link] || []).first
      total_pages         = nil

      if links_info && m = links_info.match(/<https:\/\/.+\.json\?.*page=(\d+).*>; rel=\"last\"/)
        total_pages = m[1].to_i
      end

      total_pages   ||= 1
      records_batch = records_batch.to_a

      if records_batch.any? && block_given?
        records_batch.each do |record|
          yield record
        end
      end

      if records_batch.empty? || total_pages <= 1
        return records_batch
      end

      2.upto(total_pages).each do |current_page|
        self.all(:params => http_params.merge({ :page => current_page })).to_a.each do |record|
          records_batch << record
          yield record if block_given?
        end
      end

      records_batch
    end

  end
end
