module EasyAgileBoard
  module EasyQueryPatch

    def self.included(base)
      base.include(InstanceMethods)

      base.class_eval do

        # Used in select options for 'Subtitle' in agile cards
        def main_attribute_options
          options = self.available_columns.inject([]) do |options, column|
            next options unless EasyAgileBoard::EasyQueryOutputs::KanbanOutput.default_column_names.include?(column.name.to_s)

            options << [column.caption, column.name.to_s.split('.').last]
          end

          options + additional_main_attribute_options
        end

        # Used in select options for 'Subtitle' in agile cards
        #
        # @return [Array] in format: [caption, key_name]
        # @note caption  [String] text displayed in select
        # @note key_name [String] key for finding value in entity json
        def additional_main_attribute_options
          []
        end

      end
    end

    module InstanceMethods
    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'EasyQuery', 'EasyAgileBoard::EasyQueryPatch'

