require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class JournalImportable < Importable

    def initialize(data)
      @klass = Journal
      super
    end

    def mappable?
      false
    end

    private

    def update_detail_from_map(detail, identifier, map)
      ep "identifier: #{identifier}"
      unless detail.old_value.blank?
        if (old_value = map.dig(identifier, detail.old_value))
          detail.old_value = old_value
        else
          detail.old_value = nil
          ep "old value (#{detail.old_value}) not in map['#{identifier}']"
        end
      end
      unless detail.value.blank?
        if (value = map.dig(identifier, detail.value))
          detail.value = value
        else
          detail.value = nil
          ep "value (#{detail.value}) not in map['#{identifier}']"
        end
      end
    end

    def update_attribute(journal, name, value, map, xml)
      if name == 'details'
        journal.details = []
        xml.xpath('detail').each do |detail_xml|
          detail           = JournalDetail.new
          detail.property  = detail_xml.xpath('property').text
          pk               = detail_xml.xpath('prop-key').text
          old_value_xml    = detail_xml.xpath('old-value')
          detail.old_value = old_value_xml.text unless old_value_xml.first['nil']
          value_xml        = detail_xml.xpath('value')
          detail.value     = value_xml.text unless value_xml.first['nil']
          case detail.property
          when 'attachment'
            if detail.value.nil?
              detail.prop_key = pk
            else
              detail.prop_key = map.dig('attachment', pk) || map.dig('attachment/version', pk) || map.dig('attachment_version', pk)
            end
          when 'attr'
            detail.prop_key = pk
            ep "attr #{pk}"
            case pk
            when 'assigned_to_id'
              update_detail_from_map(detail, 'user', map)
            when 'status_id'
              update_detail_from_map(detail, 'issue_status', map)
            when 'status'
              update_detail_from_map(detail, 'issue_status', map)
            when 'priority_id'
              update_detail_from_map(detail, 'issue_priority', map)
            when 'parent_id'
              update_detail_from_map(detail, 'issue', map)
            when 'parent'
              update_detail_from_map(detail, 'issue', map)
            when 'tracker_id'
              update_detail_from_map(detail, 'tracker', map)
            when 'fixed_version_id'
              update_detail_from_map(detail, 'version', map)
            when 'attachment'
              update_detail_from_map(detail, 'attachment', map)
            when 'default_assigned_to_id'
              update_detail_from_map(detail, 'user', map)
            when 'project_id'
              update_detail_from_map(detail, 'project', map)
            when 'author_id'
              update_detail_from_map(detail, 'user', map)
            when 'category_id'
              update_detail_from_map(detail, 'issue_category', map)
            when 'subject', 'description', 'done_ratio', 'start_date', 'due_date', 'estimated_hours', 'is_private'
              # nothing is needed, keep it as it is
            else
              ep "unsupported journal detail attribute, values are not updated: #{pk}"
            end
          when 'relation'
            update_detail_from_map(detail, 'issue', map)
          when 'cf'
            if new_pk = map.dig('issue_custom_field', detail.prop_key)
              detail.prop_key = new_pk
            else
              detail.prop_key = nil
              ep "value (#{detail.prop_key}) not in map['issue_custom_field']"
            end
          else
            detail.prop_key = pk
          end
          if !detail.prop_key.blank? && detail.save
            journal.details << detail
          end
        end
      else
        super
      end
    end

  end
end
