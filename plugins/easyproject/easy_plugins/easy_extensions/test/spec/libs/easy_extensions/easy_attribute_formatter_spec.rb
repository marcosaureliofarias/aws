require 'easy_extensions/spec_helper'

RSpec.describe EasyExtensions::EasyAttributeFormatter do
  let(:dummy_class) { Class.new { include EasyExtensions::EasyAttributeFormatter }.new }

  describe '#format_price' do
    let(:currency) { EasyCurrency.get_symbol('EUR').freeze }

    context 'precision 0' do
      it 'includes integer part and removes decimal par of given number' do
        I18n.available_locales.each do |locale|
          formatted_price = dummy_class.format_price(987_654.321, currency, precision: 0, locale: locale)
          expect(formatted_price).to include('987', '654', currency)
          expect(formatted_price).not_to include('3')
        end
      end

      context 'humanize true' do
        it 'includes humanized number with 2 decimal numbers' do
          I18n.available_locales.each do |locale|
            formatted_price = dummy_class.format_price(987_654.321, currency, precision: 0, locale: locale, humanize: true)
            human_unit      = I18n.t('number.human.decimal_units.units.thousand')
            expect(formatted_price).to include('987', '65', currency, human_unit)
            expect(formatted_price).not_to include('4')
          end
        end
      end
    end

    context 'precision 1' do
      it 'includes integer part and one decimal number' do
        I18n.available_locales.each do |locale|
          formatted_price = dummy_class.format_price(987_654.321, currency, precision: 1, locale: locale)
          expect(formatted_price).to include('987', '654', '3', currency)
          expect(formatted_price).not_to include('2')
        end
      end

      context 'humanize true' do
        it 'includes humanized number with 2 decimal numbers' do
          I18n.available_locales.each do |locale|
            formatted_price = dummy_class.format_price(987_654.321, currency, precision: 1, locale: locale, humanize: true)
            human_unit      = I18n.t('number.human.decimal_units.units.thousand')
            expect(formatted_price).to include('987', '65', currency, human_unit)
            expect(formatted_price).not_to include('4')
          end
        end
      end
    end

  end

end
