require 'easy_extensions/spec_helper'

RSpec.describe 'EasyPageModules::TranslatableSettings' do

  class DummyEasyPageZoneModule < EasyPageZoneModule
    include EasyPageModules::TranslatableSettings

    def translatable_keys
      [
          %w[name]
      ]
    end
  end

  let(:epzm) { DummyEasyPageZoneModule.new }
  let(:epzm_with_original_and_english_values) do
    epzm.settings = { 'name' => 'original_name', 'translations' => { 'name' => { 'en' => 'translated_name' } } }
    epzm
  end

  describe '#settings' do
    it 'gets correct value for translatable key' do
      expect(epzm_with_original_and_english_values.settings['name']).to eq('translated_name')
    end
  end

  describe '#get_original_value_for' do
    it 'fetches original value' do
      # without #settings touch
      expect(epzm_with_original_and_english_values.get_original_value_for(*['name'])).to eq('original_name')

      epzm.settings # settings touch

      expect(epzm_with_original_and_english_values.get_original_value_for(*['name'])).to eq('original_name')
    end
  end

  describe '#get_translation_for' do
    it 'return correct translation' do
      settings = epzm_with_original_and_english_values.settings
      expect(epzm_with_original_and_english_values.get_translation_for(*['name'], settings: settings)).to eq('translated_name')
    end
  end

  describe '#translations_for_keys' do
    it 'return correct translations' do
      expect(epzm_with_original_and_english_values.translations_for_keys(*['name'])).to eq('en' => 'translated_name')
    end
  end

  describe '#deep_set' do
    it 'buries value into  given hash' do
      hash = {}
      keys = %w[a b c]
      epzm.deep_set(hash, 'newValue', *keys)
      expect(hash.dig(*keys)).to eq('newValue')
    end
  end

end
