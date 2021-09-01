require 'easy_extensions/spec_helper'

describe EasyAssetsController do

  describe '#typography' do

    it 'theme er18' do
      with_easy_settings(ui_theme: 'themes/er18/er18.css') do
        get :typography, format: :css
        expect(response).to have_http_status(200)
      end
    end

    let(:theme) { FactoryBot.create(:easy_theme_design, in_use: true) }

    context 'with nonexist file from designer' do
      it 'user classic theme', skip: !Redmine::Plugin.installed?(:easy_theme_designer) do
        allow(theme).to receive(:asset_url).and_return('non_exist/path')
        get :typography, format: :css
        expect(response).to have_http_status(200)
      end

      it 'back 404' do
        allow_any_instance_of(described_class).to receive(:file_path).and_return('non_exist/path')
        get :typography, format: :css
        expect(response).to have_http_status(404)
      end

    end
  end
end
