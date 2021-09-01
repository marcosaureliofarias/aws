module EasyContactPatch
  module EasyEntityActivityAttendeePatch

    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        class << self
           alias_method_chain :all_attendees_values, :easy_contacts
        end
      end
    end

    module ClassMethods

      def all_attendees_values_with_easy_contacts(term, limit = nil)
        (all_attendees_values_without_easy_contacts(term, limit) + EasyContact.includes(:easy_contact_type).visible.like(term).limit(limit).map{|u| {value: u.to_s + " (#{l :field_easy_contact})", id: 'EasyContact_' + u.id.to_s} }).sort_by{|x| x[:value]}.first(limit)
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'EasyEntityActivityAttendee', 'EasyContactPatch::EasyEntityActivityAttendeePatch'
