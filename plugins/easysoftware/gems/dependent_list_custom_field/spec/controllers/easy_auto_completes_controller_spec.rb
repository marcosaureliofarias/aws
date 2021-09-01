RSpec.describe EasyAutoCompletesController, logged: :admin do

  describe '#dependent_list_possible_values' do
    include_context 'depended custom field'
    let(:issue) { FactoryBot.build(:issue) }
    let(:params) do
      h = { custom_field_id: brand_cf.id, customized_type: 'Issue', customized_id: issue.id }
      h[:autocomplete_action] = 'dependent_list_possible_values'
      h[:format] = :json
      h
    end

    before do
      allow(Issue).to receive(:find) { issue }
    end
    subject { JSON.parse(response.body) }

    context 'parent cf list' do
      context 'no value selected' do
        it do
          allow(issue).to receive(:custom_field_value) { [''] }
          expected = []
          get :index, params: params

          expect(subject).to match_array(expected)
        end
      end

      context 'single value selected' do
        it do
          allow(issue).to receive(:custom_field_value) { 'Tesla' }
          expected = ['Model3', 'ModelS', 'ModelY'].map {|v| { 'text' => v, 'value' => v } }
          get :index, params: params

          expect(subject).to match_array(expected)
        end
      end

      context 'multiple values selected' do
        it do
          allow(issue).to receive(:custom_field_value) { ['Tesla', 'Skoda'] }
          expected = ['Fabia', 'Octavia', 'Superb', 'Model3', 'ModelS', 'ModelY'].map {|v| { 'text' => v, 'value' => v } }
          get :index, params: params

          expect(subject).to match_array(expected)
        end
      end
    end
  end

end
