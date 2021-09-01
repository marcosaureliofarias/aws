require 'easy_extensions/spec_helper'

describe EpmTranslatableNoticeboard, logged: :admin do
  let(:epm_translatable_noticeboard) { EpmTranslatableNoticeboard.new }
  let(:epzm) { EasyPageZoneModule.new }
  let(:epzm_parsed) do
    result          = epzm.dup
    result.settings = {
        'data' => {
            'en' => {
                'title'   => '<p>Title</p>',
                'content' => '<p>Content</p>',
            },
            'cs' => {
                'title'   => '<p>Nadpis</p>',
                'content' => '<p>Telo</p>',
            },
        },
    }
    result
  end
  let(:epzm_with_settings_as_json_string) do
    result                  = epzm.dup
    result.settings['data'] = epzm_parsed.settings['data'].to_json
    result
  end

  describe '#page_zone_module_before_save' do
    it 'Parses JSON string and calls #deep_transform_values on parsed value' do
      epm_translatable_noticeboard.page_zone_module_before_save(epzm_with_settings_as_json_string)
      expect(epzm_with_settings_as_json_string.settings['data']).to eq(epzm_parsed.settings['data'])
    end
  end

  describe '#data_for_language' do
    it 'gets EN value from epm settings' do
      value = epm_translatable_noticeboard.data_for_language(epzm_parsed.settings, :en)
      expect(value).to eq epzm_parsed.settings['data']['en']
    end

    it 'gets CS value from epm settings' do
      value = epm_translatable_noticeboard.data_for_language(epzm_parsed.settings, 'cs')
      expect(value).to eq epzm_parsed.settings['data']['cs']
    end

    it 'gets EN value from epm settings as fallback' do
      value = epm_translatable_noticeboard.data_for_language(epzm_parsed.settings, :klingon)
      expect(value).to eq epzm_parsed.settings['data']['en']
    end
  end
end
