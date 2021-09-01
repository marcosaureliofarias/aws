# module DependentListCustomField::Test
#   module Helper
#   end
# end
require 'redmine/field_format/dependent_list'
RSpec.shared_context 'depended custom field' do
  let(:automaker_cf) { FactoryBot.create :issue_custom_field, name: 'Automaker', field_format: 'list', is_for_all: true, possible_values: %w[BMW Skoda Tesla] }
  let(:brand_cf) do
    FactoryBot.create :issue_custom_field, name: 'Model', field_format: 'dependent_list', is_for_all: true,
                                           possible_values: %w[1series 2series 3series 4series 5series Fabia Octavia Superb Model3 ModelS ModelY],
                                           settings: {
                                             dependent_custom_field: automaker_cf.id,
                                             dependency_settings: {
                                               '0' => { '0' => '1', '1' => '1', '2' => '1', '3' => '1', '4' => '1' },
                                               '1' => { '5' => '1', '6' => '1', '7' => '1' },
                                               '2' => { '8' => '1', '9' => '1', '10' => '1' }
                                             }
                                           }
  end
end
