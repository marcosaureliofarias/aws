require 'easy_extensions/spec_helper'

feature 'Moment locales', js: true, logged: :admin do

  describe 'should select' do

    after(:each) do
      allow(User.current).to receive(:language).and_call_original
    end

    it 'en' do
      allow(User.current).to receive(:language).and_return('en')
      visit home_path
      expect(evaluate_script('moment("2018-05-15").from("2018-05-23")')).to eq('8 days ago')
    end

    it 'cs' do
      allow(User.current).to receive(:language).and_return('cs')
      visit home_path
      expect(evaluate_script('moment("2018-05-15").from("2018-05-23")')).to eq('před 8 dny')
    end

    it 'zh-cn' do
      allow(User.current).to receive(:language).and_return('zh')
      visit home_path
      expect(evaluate_script('moment("2018-05-15").from("2018-05-23")')).to eq('8 天前')
    end
  end
end