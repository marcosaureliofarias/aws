class EasyEntityImportAttributesAssignment < ActiveRecord::Base

  belongs_to :easy_entity_import

  validates :easy_entity_import_id, :entity_attribute, presence: true
  validates :source_attribute, presence: true, if: ->(e) { !e.is_custom? }
  validates :value, presence: true, if: ->(e) { e.is_custom? }

  attr_accessor :allow_find_by_external_id, :format

end
