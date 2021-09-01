require 'easy_extensions/spec_helper'

describe I18n, null: true do
  let(:numbers) { Array.new(8, &Proc.new { |n| 5 * (10 ** (n * 3)) }).unshift(0, 1) }

  describe 'number_to_human_size' do # 5 => "5 Bytes", 5000 => "5 kB"...

    I18n.available_locales.each do |locale|
      it "should generate number_to_human_size on locale #{locale}" do
        numbers.each do |number|
          str = nil
          expect {
            str = number_to_human_size(number, locale: locale)
          }.not_to raise_error
          expect(str).to be_present
          expect(str).to be_a String
        end
      end
    end

  end

  describe 'number_to_human' do # 5000 => "5 Thousand"...

    I18n.available_locales.each do |locale|
      it "should generate number_to_human on locale #{locale}" do
        numbers.each do |number|
          str = nil
          expect {
            str = number_to_human(number, locale: locale)
          }.not_to raise_error
          expect(str).to be_present
          expect(str).to be_a String
        end
      end
    end

  end

  describe 'month names' do
    I18n.available_locales.each do |locale|
      it "validate #{locale}" do
        expect(Array(I18n.t('date.month_names', locale: locale)).compact.size).to eq(12)
        expect(Array(I18n.t('date.abbr_month_names', locale: locale)).compact.size).to eq(12)
        expect(Array(I18n.t('date.day_names', locale: locale)).compact.size).to eq(7)
        expect(Array(I18n.t('date.abbr_day_names', locale: locale)).compact.size).to eq(7)
      end
    end
  end

  it 'should not raise an exception with unknown locale' do
    expect { I18n.t(:field_author, :locale => :aa) }.not_to raise_error
  end

end
