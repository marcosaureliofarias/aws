module EasyPatch
  module ActiveRecordPatch

    def self.included(base)

      base.class_eval do

        class << self

          # remove validation
          # if validator_name isn't specified, complete validation will be removed
          def remove_validation(attr_name, validator_name = nil)
            if validator_name.nil?
              _validators[attr_name].each do |validator|
                validator.attributes.delete(attr_name)
              end
            else
              class_name = (validator_name.gsub('validates_', '').gsub('_of', '') + '_validator').camelize
              _validators[attr_name].select { |v| v.class.name.rpartition('::')[2] == class_name }.each do |validator|
                validator.attributes.delete(attr_name)
              end
            end
            _validators[attr_name].delete_if { |v| v.attributes.empty? || !v.attributes.include?(attr_name) }
            _validators.delete_if { |k, v| v.empty? }
          end

        end

      end
    end

  end
end
EasyExtensions::PatchManager.register_patch_to_be_first 'ActiveRecord::Base', 'EasyPatch::ActiveRecordPatch', :first => true
