class EasyEntityAttributeMap < ActiveRecord::Base
  include Redmine::SafeAttributes
  validates :entity_from_type, :entity_from_attribute, :presence => true
  validates :entity_to_type, :entity_to_attribute, :presence => true

  safe_attributes 'entity_from_type', 'entity_from_attribute', 'entity_to_attribute', 'entity_to_type'

  [:from, :to].each do |m|
    define_method :"entity_#{m}" do
      x = send("entity_#{m}_type").presence
      x.constantize if x
    end

    define_method :"entity_#{m}_available_attributes" do
      x = send("entity_#{m}")
      x && x.associated_query_class.new.available_columns || []
    end

    define_method :"entity_#{m}_possible_attributes" do
      possible_map_attributes[m]
    end

    # return @easy_from_attribute_column unless @easy_from_attribute_column.nil?
    # @easy_from_attribute_column = entity_from_available_attributes.detect{ |c| c.name == entity_from_attribute }
    define_method :"entity_#{m}_attribute_column" do
      n = instance_variable_get(:"@entity_#{m}_attribute_column")
      return n unless n.nil?
      instance_variable_set(:"@entity_#{m}_attribute_column", send("entity_#{m}_available_attributes").detect { |c| c.name == send("entity_#{m}_attribute").to_sym })
    end

    define_method :"entity_#{m}_attribute_name" do
      col = send("entity_#{m}_attribute_column")
      col.caption if col
    end
  end

  def exists_mappings
    @exists_mappings ||= EasyEntityAttributeMap.where(:entity_from_type => self.entity_from_type, :entity_to_type => self.entity_to_type).to_a
  end

  def possible_map_attributes
    return @possible_map_attributes unless @possible_map_attributes.nil?
    exists_mapping_from_attributes, exists_mapping_to_attributes = Array.new, Array.new
    exists_mappings.each do |e|
      exists_mapping_from_attributes << e.entity_from_attribute
      exists_mapping_to_attributes << e.entity_to_attribute
    end

    @possible_map_attributes = {
        :from => entity_from_available_attributes.select { |c| !c.name.to_s.in?(exists_mapping_from_attributes) },
        :to   => entity_to_available_attributes.select { |c| !c.name.to_s.in?(exists_mapping_to_attributes) }
    }
  end
end
